#!/usr/bin/env ruby

# frozen_string_literal: true

# OAuth device flow test

require 'json'
require 'octokit'
require 'rest-client'

CLIENT_ID = 'ea6dfdbf6e585e59fac6'

payload = {
  client_id: CLIENT_ID,
  scope: 'repo gist delete_repo'
}

resp = RestClient.post(
  'https://github.com/login/device/code',
  payload.to_json,
  content_type: :json,
  accept: :json
)

json = JSON.parse(resp.body)
p json

device_code = json['device_code']
user_code = json['user_code']
verification_url = json['verification_uri']
expires_in = json['expires_in']
interval = json['interval']

expire_time = Time.now + expires_in

puts <<-EOM
Please enter the code #{user_code} at #{verification_url}
This code will expire in #{expires_in} seconds.
EOM

payload = {
  client_id: CLIENT_ID,
  device_code: device_code,
  grant_type: 'urn:ietf:params:oauth:grant-type:device_code'
}

access_token = nil

while Time.now < expire_time do
  sleep(interval)

  resp = RestClient.post(
    'https://github.com/login/oauth/access_token',
    payload.to_json,
    content_type: :json,
    accept: :json
  )

  json = JSON.parse(resp.body)
  p json
  if json.key?('access_token')
    access_token = json['access_token']
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
