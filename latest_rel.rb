#!/usr/bin/env ruby

require 'octokit'
require 'optparse'
require 'pp'
require 'ostruct'

def report_latest client, repo
  unless client.repository?(repo)
    warn "Repo #{repo} does not exist"
    return
  end
  yield repo, client.latest_release(repo)
rescue Octokit::NotFound
  warn "#{repo}: No releases"
end

def parse_opts
  options = OpenStruct.new(debug: false)

  opt_parser = OptionParser.new { |opts|
    opts.banner = "Usage: #{File.basename $PROGRAM_NAME} [options] owner/repo [owner/repo ...]"

    opts.on('-l', '--long', 'Long format') {
      options.long = true
    }

    opts.on('-d', '--debug', 'Debug mode') {
      options.debug = true
    }

    opts.on('-h', '--help', 'Prints this help') {
      puts opts
      exit
    }
  }

  opt_parser.parse!

  if ARGV.size < 1
    puts opt_parser.help
    exit
  end

  options
end

KB_SIZE = 1024.0
MB_SIZE = KB_SIZE * 1024.0
GB_SIZE = MB_SIZE * 1024.0

def fmt_size size
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

options = parse_opts

# Check if netrc gem is installed.
got_netrc = Gem::Specification.find_all_by_name('netrc').any?

client = Octokit::Client.new(netrc: got_netrc)

ARGV.each { |arg|
  unless arg =~ %r{^[^/]+/[^/]+$}
    warn "Invalid repo '#{arg}'. Must be in the format owner/repo"
    next
  end
  report_latest(client, arg) { |repo, rel|
    if options.debug
      puts "#{repo}:"
      pp rel
      puts
    elsif options.long
      puts "#{repo}: #{rel.name} at #{rel.published_at.localtime.strftime '%Y-%m-%d %H:%M'}"
      rel.assets.each { |asset|
        puts " * #{asset.name} (#{fmt_size asset.size}): #{asset.browser_download_url}"
      }
      puts <<-EOM
 * tarball: #{rel.tarball_url}
 * zipball: #{rel.zipball_url}

      EOM
    else
      puts "#{repo}: #{rel.name} at #{rel.published_at.localtime.strftime '%Y-%m-%d %H:%M'}"
    end
  }
}

__END__
