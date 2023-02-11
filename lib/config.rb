# frozen_string_literal: true

require 'hocon'

# Config file manager
class Config
  DEFAULT_TOKEN_FILE = '~/.githubtools.token'
  DEFAULT_PORT = 3501

  def initialize
    @config = nil
  end

  def load_config(fname)
    raise "Config file #{fname} not found or not readable" unless File.readable?(fname)

    @config = Hocon.load(fname)

    @port = @config['port'] || DEFAULT_PORT
    @token_file = @config['token_file'] || DEFAULT_TOKEN_FILE
    @client_id = @config['client_id']
    @client_secret = @config['client_secret']
  end

  attr_reader :port, :token_file, :client_id, :client_secret
end

__END__

