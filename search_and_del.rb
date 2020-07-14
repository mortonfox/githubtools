#!/usr/bin/env ruby
# frozen_string_literal: true

require 'octokit'

RESULTS_SLICE = 50

def search_repos client, search_str
  repos = client.repos(nil)
  repos
    .select { |repo|
      # Consider only forks.
      # Ignore repos with #keep in the description.
      repo[:fork] && !repo[:description].to_s.downcase.include?('#keep') && repo[:name].downcase.include?(search_str.downcase)
    }
    .map { |repo| repo[:full_name] }
end

def delete_repos client, reponames
  reponames.each { |reponame|
    puts "Deleting #{reponame}..."
    client.delete_repo(reponame)
  }
end

if ARGV.empty?
  warn <<-WARNMSG
Usage: #{File.basename $PROGRAM_NAME} search-string
  WARNMSG
  exit 1
end

# Check if netrc gem is installed.
got_netrc = Gem::Specification.find_all_by_name('netrc').any?

client = Octokit::Client.new(
  auto_paginate: true,
  netrc: got_netrc
)

results = search_repos(client, ARGV.first)

results.each_slice(RESULTS_SLICE) { |rslice|
  puts 'Found the following repos:'
  rslice.each_with_index { |reponame, i| puts "#{i + 1}: #{reponame}" }
  print "Enter 'yes' to delete: "

  break unless $stdin.gets.strip.casecmp?('yes')

  delete_repos(client, rslice)
}

__END__
