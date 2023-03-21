#!/usr/bin/env ruby

# frozen_string_literal: true

# OAuth web application flow test with WEBrick server

require 'faraday'
require 'faraday/retry'
require 'launchy'
require 'octokit'
require 'securerandom'
require 'uri'
require 'webrick'

CLIENT_ID = 'ea6dfdbf6e585e59fac6'
CLIENT_SECRET = 'c4f54fc6d08a3666e2683fb84699b63289bf3627'

state = SecureRandom.hex(32)

payload = {
  client_id: CLIENT_ID,
  scope: 'repo gist delete_repo',
  state: state
}

# Run a WEBrick server to catch the callback after the user authorizes the
# app.
log = WEBrick::Log.new($stdout, WEBrick::Log::ERROR)
server = WEBrick::HTTPServer.new(Port: 3501, Logger: log, AccessLog: [])

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
  elsif code_param
    auth_mutex.synchronize { auth_code ||= code_param }
    res.body = 'Okay'
    raise WEBrick::HTTPStatus::OK
  else
    res.status = 400
    res.body = 'Missing code parameter'
    auth_mutex.synchronize { auth_error ||= res.body }
  end
}

# Suppress the favicon.ico error message.
server.mount_proc('/favicon.ico') { raise WEBrick::HTTPStatus::NotFound }

Thread.new { server.start }

url = "https://github.com/login/oauth/authorize?#{URI.encode_www_form(payload)}"
Launchy.open(url)

got_auth_result = false
until got_auth_result
  sleep(1)
  auth_mutex.synchronize { got_auth_result = true if auth_code || auth_error }
end

server.shutdown

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
