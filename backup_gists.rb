#!/usr/bin/env ruby

# frozen_string_literal: true

# Given a username, downloads all of the user's gists.

require 'finer_struct'
require 'git'
require 'octokit'
require 'optparse'
require_relative 'lib/config'
require_relative 'lib/github_auth'

GISTS_FOLDER = './gists'
DEFAULT_CONFIG_FILE = File.expand_path('~/.githubtools.conf')

def parse_cmdline
  options = FinerStruct::Mutable.new(
    config_file: DEFAULT_CONFIG_FILE,
    force_auth: false,
    username: nil
  )

  opts = OptionParser.new

  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] username"

  opts.on('-h', '-?', '--help', 'Option help') {
    puts opts
    exit
  }

  opts.on('--auth', 'Ignore saved access token and force reauthentication') {
    options.force_auth = true
  }

  opts.on('--config-file=FNAME', "Config file name. Default is #{DEFAULT_CONFIG_FILE}") { |fname|
    options.config_file = fname
  }

  opts.parse!

  if ARGV.empty?
    warn 'Error: username argument missing!'
    warn opts
    exit 1
  end

  options.username = ARGV.shift

  options
end

def backup_gists(client, username)
  gists = client.gists username
  if gists.empty?
    puts 'No gists to download.'
    return
  end

  FileUtils.mkdir_p(GISTS_FOLDER)
  Dir.chdir(GISTS_FOLDER)

  gists.each_with_index { |gist, git_indx|
    puts "#{git_indx + 1}: Cloning gist #{gist[:id]} - #{(gist[:files].first || []).first}..."

    # Find a subfolder name that does not already exist.
    subfolder = gist[:id]
    if Dir.exist? subfolder
      i = 1
      i += 1 while Dir.exist? "#{subfolder}-#{i}"
      subfolder = "#{subfolder}-#{i}"
    end

    Git.clone gist[:git_pull_url], subfolder
  }
end

options = parse_cmdline

config = Config.new
config.load_config(options.config_file)

auth = GithubAuth.new(config: config, force_auth: options.force_auth)
access_token = auth.access_token

client = Octokit::Client.new(auto_paginate: true, access_token: access_token)

backup_gists(client, options.username)

__END__
