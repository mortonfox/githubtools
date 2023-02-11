#!/usr/bin/env ruby

# frozen_string_literal: true

require 'json'
require 'launchy'
require 'rest-client'
require 'uri'
require 'webrick'

payload = {
  client_id: 'ea6dfdbf6e585e59fac6',
  scope: 'repo gist',
  state: "helloworld#{Time.now.to_i}"
}

# Run a WEBrick server to catch the callback after the user authorizes the
# app.
log = WEBrick::Log.new($stdout, WEBrick::Log::ERROR)
server = WEBrick::HTTPServer.new(Port: 3501, Logger: log, AccessLog: [])

auth_mutex = Mutex.new
auth_code = nil

server.mount_proc('/callback') { |req, res|
  code_param = req.query['code']
  if code_param
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

url = 'https://github.com/login/oauth/authorize?' + URI.encode_www_form(payload)
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
  client_id: 'ea6dfdbf6e585e59fac6',
  client_secret: 'c4f54fc6d08a3666e2683fb84699b63289bf3627',
  code: auth_code
}

resp = RestClient.post(
  'https://github.com/login/oauth/access_token',
  payload.to_json,
  content_type: :json,
  accept: :json
)
json = JSON.parse(resp.body)
puts "Access token = #{json['access_token']}"
puts resp.body

__END__
