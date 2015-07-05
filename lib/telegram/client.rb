require 'eventmachine'
require "em-synchrony"
require 'em-synchrony/fiber_iterator'
require 'ostruct'
require 'oj'
require 'open4'
require 'shellwords'

require 'telegram/connection'
require 'telegram/connection_pool'
require 'telegram/callback'
require 'telegram/api'
require 'telegram/models'

module Telegram
  class Client < API
    attr_reader :connection

    attr_reader :profile
    attr_reader :contacts
    attr_reader :chats

    attr_accessor :on

    def initialize(&b)
      @config = OpenStruct.new(:daemon => 'bin/telegram', :key => 'tg-server.pub', :sock => 'tg.sock', :size => 5)
      yield @config
      @connected = 0
      @stdout = nil
      @connect_callback = nil
      @on = {
        :message => nil
      }

      @profile = nil
      @contacts = []
      @chats = []
      @starts_at = nil
    end

    def execute
      command = "'#{@config.daemon}' -Ck '#{@config.key}' -I -WS '#{@config.sock}' --json"
      p command
      pid, stdin, stdout, stderr = Open4.popen4(command)
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
      data = ''
        
      loop do
        IO.select([@stdout])
        byte = @stdout.read_nonblock(2)
        data << byte
        if byte.include?("\n")
          begin
            brace = data.index('{')
            data = data[brace..-2]
            data = Oj.load(data)

          rescue
          end
          data = ''
        end
      end
    end

    def connect(&block)
      @starts_at = Time.now
      @connect_callback = block
      EM.defer(execute, create_pool)
    end

    def create_pool
      @connection = ConnectionPool.new(@config.size) do
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
        EM.defer(&method(:poll))
        update!(&@connect_callback)
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
