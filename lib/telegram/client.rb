# encoding: utf-8
require 'eventmachine'
require "em-synchrony"
require 'em-synchrony/fiber_iterator'
require 'ostruct'
require 'oj'
require 'shellwords'
require 'date'

require 'telegram/logger'
require 'telegram/connection'
require 'telegram/connection_pool'
require 'telegram/callback'
require 'telegram/api'
require 'telegram/models'
require 'telegram/events'

module Telegram
  class Client < API
    include Logging

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
      @on = {}

      @profile = nil
      @contacts = []
      @chats = []
      @starts_at = nil
      @events = EM::Queue.new

      logger.info("Initialized")
    end

    def execute
      command = "'#{@config.daemon}' -Ck '#{@config.key}' -I -WS '#{@config.sock}' --json"
      @stdout = IO.popen(command)
      loop do
        if t = @stdout.readline then
          break if t.include?('I: config')
        end
      end
      proc {}
    end

    def poll
      data = ''
      logger.info("Start polling for events")
      loop do
        begin
          byte = @stdout.read_nonblock 1
        rescue IO::WaitReadable
          IO.select([@stdout])
          retry
        rescue EOFError
          logger.error("EOFError occurred during the polling")
          return
        end
        data << byte unless @starts_at.nil?
        if byte.include?("\n")
          begin
            brace = data.index('{')
            data = data[brace..-2]
            data = Oj.load(data)
            @events << data
          rescue
          end
          data = ''
        end
      end
    end

    def process_data
      process = Proc.new { |data|
        begin
          type = case data['event']
          when 'message'
            if data['from']['id'] != @profile.id
              EventType::RECEIVE_MESSAGE
            else
              EventType::SEND_MESSAGE
            end
          end

          action = data.has_key?('action') ? case data['action']
            when 'chat_add_user'
              ActionType::CHAT_ADD_USER
            else
              ActionType::UNKNOWN_ACTION
            end : ActionType::NO_ACTION

          event = Event.new(self, type, action, data)
          @on[type].call(event) if @on.has_key?(type)
        rescue Exception => e
          logger.error("Error occurred during the processing: #{data}\n #{e.inspect} #{e.backtrace}")
        end
        @events.pop(&process)
      }
      @events.pop(&process)
    end

    def connect(&block)
      logger.info("Trying to start telegram-cli and then connect")
      @connect_callback = block
      process_data
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
        logger.info("Successfully connected to the Telegram CLI")
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
