require 'eventmachine'
require "em-synchrony"
require 'ostruct'
require 'oj'
require 'open4'
require 'shellwords'

require 'telegram/connection'
require 'telegram/api'
require 'telegram/models'

module Telegram
  class Client < API
    attr_reader :connection

    attr_reader :contacts
    attr_reader :rooms

    attr_accessor :on

    def initialize(&b)
      @config = OpenStruct.new(:daemon => 'bin/telegram', :key => 'tg-server.pub', :sock => 'tg.sock', :size => 3)
      yield @config
      @connected = 0
      @stdout = nil
      @connect_callback = nil
      @on = {
        :message => nil
      }
    end

    def execute
      command = "'#{@config.daemon}' -Ck '#{@config.key}' -WS '#{@config.sock}' --json"
      pid, stdin, stdout, stderr = Open4.popen4(command)
      stdout.sync = true
      stdout.flush
      @stdout = stdout
      loop do
        if t = @stdout.readline then
          break if t.include?('I: config')
        end
      end
      @stdout = stdout
      proc {}
    end

    def poll
      lpoll = Proc.new {
        if t = @stdout.readline then
          p t
          EM.next_tick(&lpoll)
        end
      }
      lpoll
    end

    def connect(&block)
      @connect_callback = block
      EM.defer(execute, create_pool)
    end

    def create_pool
      @connection = EM::Synchrony::ConnectionPool.new(size: @config.size) do
        client = EM.connect_unix_domain(@config.sock, Connection)
        client.on_connect = self.method(:on_connect)
        client.on_disconnect = self.method(:on_disconnect)
        client
      end
      proc {}
    end

    def on_connect
      @connected += 1
      if connected?
        EM.defer(poll)
        @connect_callback.call unless @connect_callback.nil?
      end
    end

    def on_disconnect
      @connected -= 1
    end

    def connected?
      @connected == @config.size
    end
  end
end
