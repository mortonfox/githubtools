#!/usr/bin/env ruby

# frozen_string_literal: true

# OAuth web application flow test with WEBrick server

require 'json'
require 'launchy'
require 'octokit'
require 'rest-client'
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

server.mount_proc('/callback') { |req, res|
  code_param = req.query['code']
  ret_state = req.query['state']

  if ret_state != state
    res.body = 'Returned state does not match our state'
    raise WEBrick::HTTPStatus::BadRequest
  elsif code_param
    auth_mutex.synchronize { auth_code ||= code_param }
    res.body = 'Okay'
    raise WEBrick::HTTPStatus::OK
  else
    res.body = 'Missing code parameter'
    raise WEBrick::HTTPStatus::BadRequest
  end
}

# Suppress the favicon.ico error message.
server.mount_proc('/favicon.ico') { raise WEBrick::HTTPStatus::NotFound }

Thread.new { server.start }

url = "https://github.com/login/oauth/authorize?#{URI.encode_www_form(payload)}"
Launchy.open(url)

got_auth_code = false
until got_auth_code
  sleep(1)
  auth_mutex.synchronize {
    got_auth_code = true if auth_code
  }
end

server.shutdown

puts "Code = #{auth_code}"

payload = {
  client_id: CLIENT_ID,
  client_secret: CLIENT_SECRET,
  code: auth_code
}

resp = RestClient.post(
  'https://github.com/login/oauth/access_token',
  payload.to_json,
  content_type: :json,
  accept: :json
)
json = JSON.parse(resp.body)
p json
access_token = json['access_token']
puts "Access token = #{access_token}"

client = Octokit::Client.new(access_token: access_token)
user = client.user
puts "Username = #{user.login}"

__END__
