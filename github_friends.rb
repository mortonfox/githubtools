#!/usr/bin/env ruby

# frozen_string_literal: true

# Given a username, retrieves the user's following and followers and categorize them into:
# - mutual followers
# - only followers
# - only following

require 'finer_struct'
require 'octokit'
require 'optparse'
require_relative 'lib/config'
require_relative 'lib/github_auth'

DEFAULT_CONFIG_FILE = File.expand_path('~/.githubtools.conf')

def parse_cmdline
  options = FinerStruct::Mutable.new(
    config_file: DEFAULT_CONFIG_FILE,
    force_auth: false,
    mutual_friends: false,
    only_friends: false,
    only_followers: false,
    username: nil
  )

  opts = OptionParser.new

  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] username"

  opts.on('-h', '-?', '--help', 'Option help') {
    puts opts
    exit
  }

  opts.on('-m', '--mutual', 'Show mutual friends') {
    options.mutual_friends = true
  }

  opts.on('-r', '--only-friends', 'Show only-friends') {
    options.only_friends = true
  }

  opts.on('-o', '--only-followers', 'Show only-followers') {
    options.only_followers = true
  }

  opts.on('--auth', 'Ignore saved access token and force reauthentication') {
    options.force_auth = true
  }

  opts.on('--config-file=FNAME', "Config file name. Default is #{DEFAULT_CONFIG_FILE}") { |fname|
    options.config_file = fname
  }

  opts.separator '  If none of -m/-r/-o are specified, display all 3 categories.'

  opts.parse!

  if ARGV.empty?
    warn 'Error: username argument missing!'
    warn opts
    exit 1
  end

  options.username = ARGV.first

  if !options.mutual_friends && !options.only_friends && !options.only_followers
    # If none of the 3 options are specified, show everything.
    options.mutual_friends = options.only_friends = options.only_followers = true
  end

  options
end

def show_list(list, userdata)
  if list.empty?
    puts 'n/a'
    return
  end

  list.sort_by(&:downcase).each_with_index { |username, i|
    puts "#{i + 1}: #{username} ( #{userdata[username].html_url} )"
  }
end

def report_ff(client, options)
  username = options.username

  userdata = {}
  following = Set.new
  followers = Set.new

  begin
    client.following(username).each { |user|
      userdata[user.login] = user
      following << user.login
    }
    client.followers(username).each { |user|
      userdata[user.login] = user
      followers << user.login
    }
  rescue Octokit::NotFound
    warn "User #{username} not found!"
    exit 1
  end

  if options.mutual_friends
    puts 'Mutual following:'
    show_list(following & followers, userdata)
    puts
  end

  if options.only_friends
    puts 'Only following:'
    show_list(following - followers, userdata)
    puts
  end

  if options.only_followers
    puts 'Only followers:'
    show_list(followers - following, userdata)
    puts
  end
end

options = parse_cmdline

config = Config.new
config.load_config(options.config_file)

auth = GithubAuth.new(config: config, force_auth: options.force_auth)
access_token = auth.access_token

client = Octokit::Client.new(auto_paginate: true, access_token: access_token)

report_ff(client, options)

__END__
