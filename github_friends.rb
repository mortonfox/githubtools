#!/usr/bin/env ruby

# frozen_string_literal: true

# Given a username, retrieves the user's following and followers and categorize them into:
# - mutual followers
# - only followers
# - only following

require 'octokit'
require 'set'
require 'optparse'

def show_list list
  if list.empty?
    puts 'n/a'
    return
  end

  list.sort_by(&:downcase).each_with_index { |name, i|
    puts "#{i + 1}: #{name}"
  }
end

def report_ff username, options
  # Check if netrc gem is installed.
  got_netrc = Gem::Specification.find_all_by_name('netrc').any?

  client = Octokit::Client.new(
    auto_paginate: true,
    netrc: got_netrc
  )

  begin
    following = Set.new(client.following(username).map(&:login))
    followers = Set.new(client.followers(username).map(&:login))
  rescue Octokit::NotFound
    warn "User #{username} not found!"
    exit 1
  end

  if !options[:mutual_friends] && !options[:only_friends] && !options[:only_followers]
    # If none of the 3 options are specified, show everything.
    options[:mutual_friends] = options[:only_friends] = options[:only_followers] = true
  end

  if options[:mutual_friends]
    puts 'Mutual following:'
    show_list following & followers
    puts
  end

  if options[:only_friends]
    puts 'Only following:'
    show_list following - followers
    puts
  end

  if options[:only_followers]
    puts 'Only followers:'
    show_list followers - following
    puts
  end
end

def parse_cmdline
  options = {}

  optp = OptionParser.new

  optp.banner = "Usage: #{File.basename $PROGRAM_NAME} [options] username"

  optp.on('-h', '-?', '--help', 'Option help') {
    puts optp
    exit
  }

  optp.on('-m', '--mutual', 'Show mutual friends') {
    options[:mutual_friends] = true
  }

  optp.on('-r', '--only-friends', 'Show only-friends') {
    options[:only_friends] = true
  }

  optp.on('-o', '--only-followers', 'Show only-followers') {
    options[:only_followers] = true
  }

  optp.separator '  If none of -m/-r/-o are specified, display all 3 categories.'

  optp.parse!

  if ARGV.empty?
    warn 'Error: username argument missing!'
    warn optp
    exit 1
  end

  options[:username] = ARGV.first

  options
end

options = parse_cmdline
report_ff(options[:username], options)

__END__
