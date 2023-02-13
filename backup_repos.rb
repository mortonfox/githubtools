#!/usr/bin/env ruby

# frozen_string_literal: true

# Given a username, downloads all the user's repositories.
# Produces a git bundle and a zip file (using git archive) of each repository,
# ready for backing up.

require 'fileutils'
require 'finer_struct'
require 'git'
require 'octokit'
require 'optparse'
require_relative 'lib/config'
require_relative 'lib/github_auth'

REPOS_FOLDER = './repos'

DEFAULT_CONFIG_FILE = File.expand_path('~/.githubtools.conf')

def parse_cmdline
  options = FinerStruct::Mutable.new(
    config_file: DEFAULT_CONFIG_FILE,
    force_auth: false,
    username: nil
  )

  opts = OptionParser.new

  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] [username]"

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

  opts.separator("\nIf username is specified, back up that user's public repos. If username is not specified, back up the authenticated user's public and private repos.")

  opts.parse!

  options.username = ARGV.shift

  options
end

def backup_repos(client, username)
  repos = client.repos(username)

  # Backup only our own repos, not forks.
  repos.reject! { |repo| repo[:fork] }

  if repos.empty?
    puts 'No repositories to download.'
    return
  end

  FileUtils.mkdir_p(REPOS_FOLDER)
  Dir.chdir(REPOS_FOLDER)

  repos.each_with_index { |repo, repo_indx|
    puts "#{repo_indx + 1}: Cloning repo #{repo[:full_name]}..."

    git_url = repo[:ssh_url]

    clone_and_bundle(git_url, find_new_subfolder(repo[:name]))

    next unless repo[:has_wiki]

    wiki_name = "#{repo[:name]}.wiki"
    wiki_clone_url = git_url.gsub(/\.git$/, '.wiki\&')

    begin
      clone_and_bundle(wiki_clone_url, find_new_subfolder(wiki_name))
    rescue StandardError => e
      warn "Error backing up repo wiki #{wiki_name}: #{e}"
    end
  }
end

# Find a subfolder name that does not already exist.
def find_new_subfolder(subfolder)
  if Dir.exist?(subfolder)
    i = 1
    i += 1 while Dir.exist? "#{subfolder}-#{i}"
    subfolder = "#{subfolder}-#{i}"
  end
  subfolder
end

def clone_and_bundle(clone_url, subfolder)
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

options = parse_cmdline

config = Config.new
config.load_config(options.config_file)

auth = GithubAuth.new(config: config, force_auth: options.force_auth)
access_token = auth.access_token

client = Octokit::Client.new(auto_paginate: true, access_token: access_token)

backup_repos(client, options.username)

__END__
