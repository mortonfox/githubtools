#!/usr/bin/env ruby
# frozen_string_literal: true

# Search for fork repos with names matching the given string and offer to delete them.

require 'finer_struct'
require 'octokit'
require 'optparse'
require_relative 'lib/config'
require_relative 'lib/github_auth'

RESULTS_SLICE = 50

DEFAULT_CONFIG_FILE = File.expand_path('~/.githubtools.conf')

def parse_cmdline
  options = FinerStruct::Mutable.new(
    config_file: DEFAULT_CONFIG_FILE,
    force_auth: false,
    search_string: nil
  )

  opts = OptionParser.new

  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] search-string"

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
    warn 'Error: search string argument missing!'
    warn opts
    exit 1
  end

  options.search_string = ARGV.shift

  options
end

def search_repos(client, search_str)
  repos = client.repos(nil)
  repos
    .select { |repo|
      # Consider only forks.
      # Ignore repos with #keep in the description.
      repo[:fork] && !repo[:description].to_s.downcase.include?('#keep') && repo[:name].downcase.include?(search_str.downcase)
    }
    .map { |repo| repo[:full_name] }
end

def delete_repos(client, reponames)
  reponames.each { |reponame|
    puts "Deleting #{reponame}..."
    client.delete_repo(reponame)
  }
end

options = parse_cmdline

config = Config.new
config.load_config(options.config_file)

auth = GithubAuth.new(config: config, force_auth: options.force_auth)
access_token = auth.access_token

client = Octokit::Client.new(auto_paginate: true, access_token: access_token)

results = search_repos(client, options.search_string)

results.each_slice(RESULTS_SLICE) { |rslice|
  puts 'Found the following repos:'
  rslice.each_with_index { |reponame, i| puts "#{i + 1}: #{reponame}" }
  print "Enter 'yes' to delete: "

  break unless $stdin.gets.strip.casecmp?('yes')

  delete_repos(client, rslice)
}

__END__
