require 'eventmachine'
require "em-synchrony"
require 'ostruct'
require 'oj'

require 'telegram/connection'
require 'telegram/models'

module Telegram
  class Client
    attr_reader :connection

    def initialize(&b)
      @config = OpenStruct.new(:host => nil, :port => nil, :size => 10)
      yield @config
      @connected = 0
    end

    def connect(&block)
      @connection = EM::Synchrony::ConnectionPool.new(size: @config.size) do
        client = @config.port.nil? ? EM.connect_unix_domain(@config.host, Connection) \
                  : EM.connect(@config.host, @config.port, Connection)
        client.on_connect = self.method(:on_connect)
        client
      end
      @connect_callback = block
    end

    def on_connect
      @connected += 1
      @connect_callback.call if not @connect_callback.nil? and connected?
    end

    def connected?
      @connected == @config.size
    end

    def contact_list(&cb)
      @connection.communicate('contact_list')
    end
  end
end
