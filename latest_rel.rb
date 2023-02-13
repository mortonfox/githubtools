#!/usr/bin/env ruby

# frozen_string_literal: true

# Shows info about latest releases from the specified repos.

require 'finer_struct'
require 'octokit'
require 'optparse'
require_relative 'lib/config'
require_relative 'lib/github_auth'

DEFAULT_CONFIG_FILE = File.expand_path('~/.githubtools.conf')

def parse_cmdline
  options = FinerStruct::Mutable.new(
    config_file: DEFAULT_CONFIG_FILE,
    force_auth: false,
    debug: false,
    long: false
  )

  opts = OptionParser.new

  opts.banner = "Usage: #{File.basename $PROGRAM_NAME} [options] owner/repo [owner/repo ...]"

  opts.on('-h', '-?', '--help', 'Option help') {
    puts opts
    exit
  }

  opts.on('-l', '--long', 'Long format') {
    options.long = true
  }

  opts.on('-d', '--debug', 'Debug mode') {
    options.debug = true
  }

  opts.on('--auth', 'Ignore saved access token and force reauthentication') {
    options.force_auth = true
  }

  opts.on('--config-file=FNAME', "Config file name. Default is #{DEFAULT_CONFIG_FILE}") { |fname|
    options.config_file = fname
  }

  opts.parse!

  if ARGV.empty?
    puts opt_parser.help
    exit
  end

  options

  # List of repos will be in ARGV
end

def report_latest(client, repo)
  unless client.repository?(repo)
    warn "Repo #{repo} does not exist"
    return
  end
  yield repo, client.latest_release(repo)
rescue Octokit::NotFound
  warn "#{repo}: No releases"
end

KB_SIZE = 1024.0
MB_SIZE = KB_SIZE * 1024.0
GB_SIZE = MB_SIZE * 1024.0

def fmt_size(size)
  if size >= GB_SIZE
    format('%.2f GB', size / GB_SIZE)
  elsif size >= MB_SIZE
    format('%.2f MB', size / MB_SIZE)
  elsif size >= KB_SIZE
    format('%.2f KB', size / KB_SIZE)
  else
    size.to_s
  end
end

options = parse_cmdline

config = Config.new
config.load_config(options.config_file)

auth = GithubAuth.new(config: config, force_auth: options.force_auth)
access_token = auth.access_token

client = Octokit::Client.new(access_token: access_token)

ARGV.each { |arg|
  unless arg.match?(%r{^[^/]+/[^/]+$})
    warn "Invalid repo '#{arg}'. Must be in the format owner/repo"
    next
  end

  report_latest(client, arg) { |repo, rel|
    if options.debug
      puts "#{repo}:"
      puts rel.inspect
      puts
    elsif options.long
      puts "#{repo}: #{rel.name} at #{rel.published_at.localtime.strftime('%Y-%m-%d %H:%M')}"
      rel.assets.each { |asset|
        puts " * #{asset.name} (#{fmt_size(asset.size)}): #{asset.browser_download_url}"
      }
      puts <<-DLOADURLS
 * tarball: #{rel.tarball_url}
 * zipball: #{rel.zipball_url}

      DLOADURLS
    else
      puts "#{repo}: #{rel.name} at #{rel.published_at.localtime.strftime('%Y-%m-%d %H:%M')}"
    end
  }
}

__END__
