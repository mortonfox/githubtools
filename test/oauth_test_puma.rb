#!/usr/bin/env ruby

# frozen_string_literal: true

# OAuth web application flow test with Puma server

require 'faraday'
require 'faraday/retry'
require 'launchy'
require 'octokit'
require 'puma'
require 'rack'
require 'securerandom'

CLIENT_ID = 'ea6dfdbf6e585e59fac6'
CLIENT_SECRET = 'c4f54fc6d08a3666e2683fb84699b63289bf3627'

state = SecureRandom.hex(32)

payload = {
  client_id: CLIENT_ID,
  scope: 'repo gist delete_repo',
  state: state
}

auth_mutex = Mutex.new
auth_code = nil
auth_error = nil

server = Puma::Server.new(
  Rack::Builder.new do
    map('/callback') do
      run lambda { |env|
        query = Rack::Utils.parse_query(env['QUERY_STRING'])
        ret_state = query['state']
        code_param = query['code']

        if ret_state != state
          error_msg = 'Returned state does not match our state'
          auth_mutex.synchronize { auth_error ||= error_msg }
          [400, { 'content-type' => 'text/plain' }, [error_msg]]
        elsif code_param
          auth_mutex.synchronize { auth_code ||= code_param }
          [200, { 'content-type' => 'text/plain' }, ['Okay']]
        else
          error_msg = 'Missing code parameter'
          auth_mutex.synchronize { auth_error ||= error_msg }
          [400, { 'content-type' => 'text/plain' }, [error_msg]]
        end
      }
    end

    map('/favicon.ico') do
      run -> { [404, { 'content-type' => 'text/plain' }, ['Not found']] }
    end
  end
)

server.add_tcp_listener('0.0.0.0', 3501)
server.run

url = "https://github.com/login/oauth/authorize?#{Rack::Utils.build_query(payload)}"
Launchy.open(url)

got_auth_result = false
until got_auth_result
  sleep(1)
  auth_mutex.synchronize { got_auth_result = true if auth_code || auth_error }
end

server.stop

raise "Received the following callback error: #{auth_error}" if auth_error

puts "Code = #{auth_code}"

payload = {
  client_id: CLIENT_ID,
  client_secret: CLIENT_SECRET,
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
token = resp.body
access_token = token['access_token']
puts "Access token = #{access_token}"

client = Octokit::Client.new(access_token: access_token)
user = client.user
puts "Username = #{user.login}"

__END__
