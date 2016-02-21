#!/usr/bin/env ruby

require 'octokit'

def report_latest client, repo
  # require 'pp'
  # pp client.latest_release(repo)
  unless client.repository?(repo)
    warn "Repo #{repo} does not exist"
    return
  end
  latest = client.latest_release(repo)
  puts "#{repo}: #{latest.name} #{latest.published_at}"
rescue Octokit::NotFound
  warn "#{repo}: No releases"
end

if ARGV.size < 1
  puts <<-EOM
Usage: #{File.basename $PROGRAM_NAME} owner/repo [owner/repo ...]
  EOM
  exit
end

# Check if netrc gem is installed.
got_netrc = Gem::Specification.find_all_by_name('netrc').any?

client = Octokit::Client.new(netrc: got_netrc)

ARGV.each { |arg|
  unless arg =~ %r(^[^/]+/[^/]+$)
    warn "Invalid repo '#{arg}'. Must be in the format owner/repo"
    next
  end
  report_latest client, arg
}

__END__
