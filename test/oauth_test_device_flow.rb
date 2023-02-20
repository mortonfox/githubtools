#!/usr/bin/env ruby

# frozen_string_literal: true

# OAuth device flow test

require 'faraday'
require 'faraday/retry'
require 'octokit'

CLIENT_ID = 'ea6dfdbf6e585e59fac6'

payload = {
  client_id: CLIENT_ID,
  scope: 'repo gist delete_repo'
}

conn = Faraday.new { |f|
  f.request :retry
  f.request :json
  f.response :json
  f.response :raise_error
  f.headers['Accept'] = 'application/json'
}

resp = conn.post(
  'https://github.com/login/device/code',
  payload
)

token = resp.body

device_code = token['device_code']
user_code = token['user_code']
verification_url = token['verification_uri']
expires_in = token['expires_in']
interval = token['interval']

expire_time = Time.now + expires_in

puts <<~MESG
  Please enter the code #{user_code} at #{verification_url}
  This code will expire in #{expires_in} seconds.
MESG

payload = {
  client_id: CLIENT_ID,
  device_code: device_code,
  grant_type: 'urn:ietf:params:oauth:grant-type:device_code'
}

access_token = nil

while Time.now < expire_time
  sleep(interval)

  resp = conn.post(
    'https://github.com/login/oauth/access_token',
    payload
  )

  token = resp.body
  if token.key?('access_token')
    access_token = token['access_token']
    break
  end
end

if access_token.nil?
  puts 'Code expired'
  exit 1
end

puts "Access token = #{access_token}"

client = Octokit::Client.new(access_token: access_token)
user = client.user
puts "Username = #{user.login}"

__END__
