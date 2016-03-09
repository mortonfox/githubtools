#!/usr/bin/env ruby

# Given a username, downloads all of the user's gists.

require 'octokit'
require 'git'

GISTS_FOLDER = './gists'

def backup_gists username
  # Check if netrc gem is installed.
  got_netrc = Gem::Specification.find_all_by_name('netrc').any?

  client = Octokit::Client.new(
    auto_paginate: true,
    netrc: got_netrc
  )

  gists = client.gists username
  if gists.empty?
    puts 'No gists to download.'
    return
  end

  Dir.mkdir GISTS_FOLDER unless Dir.exist? GISTS_FOLDER
  Dir.chdir GISTS_FOLDER

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

if ARGV.size < 1
  puts <<-EOM
Usage: #{File.basename $PROGRAM_NAME} username
  EOM
  exit
end

backup_gists ARGV.first
__END__
