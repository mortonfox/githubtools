# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'
require 'launchy'
require 'securerandom'
require 'uri'
require 'webrick'

# Authenticate with Github
class GithubAuth
  def initialize(config:, force_auth:)
    @config = config
    @force_auth = force_auth

    @port = @config.port
    @token_file = @config.token_file
    @force_auth = force_auth

    @client_id = @config.client_id
    @client_secret = @config.client_secret

    @redirect_url = "http://localhost:#{@port}/callback"
  end

  def access_token
    tok = nil

    tok = load_token unless @force_auth

    tok = do_auth if tok.nil?

    tok
  end

  private

  def load_token
    json = JSON.parse(File.read(File.expand_path(@token_file)))
    json['access_token']
  rescue StandardError
    nil
  end

  def do_auth
    state = SecureRandom.hex(32)

    # Run a WEBrick server to catch the callback after the user authorizes the app.
    log = WEBrick::Log.new($stdout, WEBrick::Log::ERROR)
    server = WEBrick::HTTPServer.new(Port: @port, Logger: log, AccessLog: [])

    auth_mutex = Mutex.new
    auth_code = nil
    auth_error = nil

    server.mount_proc('/callback') { |req, res|
      code_param = req.query['code']
      ret_state = req.query['state']

      res['content-type'] = 'text/plain'
      if ret_state != state
        res.status = 400
        res.body = 'Returned state does not match our state'
        auth_mutex.synchronize { auth_error ||= res.body }
      elsif !code_param
        res.status = 400
        res.body = 'Missing code parameter'
        auth_mutex.synchronize { auth_error ||= res.body }
      else
        auth_mutex.synchronize { auth_code ||= code_param }
        res.body = 'Okay'
        raise WEBrick::HTTPStatus::OK
      end
    }

    # Suppress the favicon.ico error message.
    server.mount_proc('/favicon.ico') { raise WEBrick::HTTPStatus::NotFound }

    Thread.new { server.start }

    payload = {
      client_id: @client_id,
      scope: 'repo gist delete_repo',
      state: state
    }

    url = "https://github.com/login/oauth/authorize?#{URI.encode_www_form(payload)}"
    Launchy.open(url)

    got_auth_result = false
    until got_auth_result
      sleep(1)
      auth_mutex.synchronize { got_auth_result = true if auth_code || auth_error }
    end

    server.shutdown

    raise "Received the following callback error: #{auth_error}" if auth_error

    payload = {
      client_id: @client_id,
      client_secret: @client_secret,
      code: auth_code
    }

    conn = Faraday.new { |f|
      f.request :retry
      f.request :json
      f.response :json
      f.response :raise_error
      f.headers['Accept'] = 'application/json'
    }

    resp = conn.post(
      'https://github.com/login/oauth/access_token',
      payload
    )

    body = resp.body

    # Save token to token file.
    File.write(File.expand_path(@token_file), body.to_json)

    body['access_token']
  end
end

__END__
