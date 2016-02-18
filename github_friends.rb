#!/usr/bin/env ruby

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

if ARGV.size < 1
  puts <<-EOM
Usage: #{File.basename $PROGRAM_NAME} username
  EOM
  exit
end

username = ARGV.first

Octokit.auto_paginate = true

begin
  following = Set.new(Octokit.following(username).map(&:login))
  followers = Set.new(Octokit.followers(username).map(&:login))
rescue Octokit::NotFound
  warn "User #{username} not found!"
  exit 1
end

mutual = following & followers
only_following = following - followers
only_followers = followers - following

puts 'Mutual following:'
show_list mutual
puts

puts 'Only following:'
show_list only_following
puts

puts 'Only followers:'
show_list only_followers

__END__
