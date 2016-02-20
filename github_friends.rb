#!/usr/bin/env ruby

# Given a username, retrieves the user's following and followers and categorize them into:
# - mutual followers
# - only followers
# - only following

require 'octokit'
require 'set'

def show_list list
  if list.empty?
    puts 'n/a'
    return
  end

  list.sort_by(&:downcase).each_with_index { |name, i|
    puts "#{i + 1}: #{name}"
  }
end

def report_ff username
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

  puts 'Mutual following:'
  show_list following & followers
  puts

  puts 'Only following:'
  show_list following - followers
  puts

  puts 'Only followers:'
  show_list followers - following
end

if ARGV.size < 1
  puts <<-EOM
Usage: #{File.basename $PROGRAM_NAME} username
  EOM
  exit
end

report_ff ARGV.first
__END__
