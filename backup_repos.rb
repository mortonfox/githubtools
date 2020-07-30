#!/usr/bin/env ruby

# frozen_string_literal: true

# Given a username, downloads all the user's repositories.
# Produces a git bundle and a zip file (using git archive) of each repository,
# ready for backing up.

require 'fileutils'
require 'octokit'
require 'git'
require 'optparse'

REPOS_FOLDER = './repos'

def backup_repos username
  # Check if netrc gem is installed.
  got_netrc = Gem::Specification.find_all_by_name('netrc').any?

  client = Octokit::Client.new(
    auto_paginate: true,
    netrc: got_netrc
  )

  repos = client.repos username

  # Backup only our own repos, not forks.
  repos.reject! { |repo| repo[:fork] }

  if repos.empty?
    puts 'No repositories to download.'
    return
  end

  Dir.mkdir REPOS_FOLDER unless Dir.exist? REPOS_FOLDER
  Dir.chdir REPOS_FOLDER

  repos.each_with_index { |repo, repo_indx|
    puts "#{repo_indx + 1}: Cloning repo #{repo[:full_name]}..."

    clone_and_bundle(repo[:clone_url], find_new_subfolder(repo[:name]))

    next unless repo[:has_wiki]

    wiki_name = repo[:name] + '.wiki'
    wiki_clone_url = repo[:clone_url].gsub(/\.git$/, '.wiki\&')

    begin
      clone_and_bundle(wiki_clone_url, find_new_subfolder(wiki_name))
    rescue StandardError => e
      warn "Error backing up repo wiki #{wiki_name}: #{e}"
    end
  }
end

# Find a subfolder name that does not already exist.
def find_new_subfolder subfolder
  if Dir.exist?(subfolder)
    i = 1
    i += 1 while Dir.exist? "#{subfolder}-#{i}"
    subfolder = "#{subfolder}-#{i}"
  end
  subfolder
end

def clone_and_bundle clone_url, subfolder
  got_warning = false

  Git.clone clone_url, subfolder

  result = system "cd \"#{subfolder}\"; git bundle create \"../#{subfolder}.bundle\" --all"
  unless result
    warn "git bundle failed for subfolder #{subfolder}: exit code #{$CHILD_STATUS}"
    got_warning = true
  end

  # result = system "zip -9qr \"#{subfolder}.zip\" \"#{subfolder}\""
  result = system "cd \"#{subfolder}\"; git archive --format zip --prefix \"#{subfolder}/\" -9 -o \"../#{subfolder}.zip\" HEAD"
  unless result
    warn "git archive failed for subfolder #{subfolder}: exit code #{$CHILD_STATUS}"
    got_warning = true
  end

  FileUtils.rm_rf subfolder unless got_warning
end

def parse_cmdline
  optp = OptionParser.new

  optp.banner = "Usage: #{File.basename $PROGRAM_NAME} [options] [username]"

  optp.on('-h', '-?', '--help', 'Show this help') {
    puts optp
    exit
  }

  optp.separator("\nIf username is specified, back up that user's public repos. If username is not specified, back up the authenticated user's public and private repos.")

  optp.parse!

  ARGV.first
end

username = parse_cmdline
backup_repos(username)

__END__
