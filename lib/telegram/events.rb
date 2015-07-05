module Telegram
  module EventType
    UNKNOWN_EVENT = -1
    SERVICE = 0
    RECEIVE_MESSAGE = 1
    SEND_MESSAGE = 2
    ONLINE_STATUS = 3
  end

  module ActionType
    UNKNOWN_ACTION = -1
    NO_ACTION = 0
    CHAT_ADD_USER = 1
    CHAT_DEL_USER = 2
    CHAT_RENAME = 3
  end

  class Message < Struct.new(:text, :type, :from, :from_type, :raw_from, :to, :to_type, :raw_to); end

  class Event
    # @return [Number]
    attr_reader :id

    # @return [EventType]
    attr_reader :event

    # @return [ActionType]
    attr_reader :action

    # @return [Time]
    attr_reader :time

    # @return [Message]
    attr_reader :message

    # @return [TelegramMessage]
    attr_reader :tgmessage

    def initialize(client, event = EventType::UNKNOWN_EVENT, action = ActionType::NO_ACTION, data = {})
      @client = client
      @message = nil
      @tgmessage = nil
      @raw_data = data
      @time = nil

      @event = event
      @action = action

      @time = Time.at(data['date'].to_i) if data.has_key?('date')
      @time = DateTime.strptime(data['when'], "%Y-%m-%d %H:%M:%S") if @time.nil? and data.has_key?('when')

      case event
      when EventType::SERVICE
        foramt_service
      when EventType::RECEIVE_MESSAGE, EventType::SEND_MESSAGE
        format_message
        @tgmessage = TelegramMessage.new(@client, self)
      when EventType::ONLINE_STATUS
        foramt_status
      end
    end

    def format_service

    end

    def format_message
      message = Message.new
      message.text = @raw_data['text']
      message.type = @raw_data.has_key?('media') ? @raw_data['media']['type'] : 'text'
      message.raw_from = @raw_data['from']['id']
      message.from_type = @raw_data['from']['type']
      message.raw_to = @raw_data['to']['id']
      message.to_type = @raw_data['to']['type']

      from = @client.contacts.find { |c| c.id == message.raw_from }
      to = @client.contacts.find { |c| c.id == message.raw_to }
      to = @client.chats.find { |c| c.id == message.raw_to } if to.nil?

      message.from = from
      message.to = to

      @message = message

      if @message.from.nil?
        user = @raw_data['from']
        user = TelegramContact.pick_or_new(@client, user)
        @client.contacts << user unless @client.contacts.include?(user)
        @message.from = user
      end

      if @message.to.nil?
        type = @raw_data['to']['type']
        if type == 'chat'
          chat = @raw_data['to']
          chat = TelegramChat.pick_or_new(@client, chat)
          @client.chats << chat unless @client.chats.include?(chat)
          @message.from = chat
        elsif type == 'user'
          user = @raw_data['to']
          user = TelegramContact.pick_or_new(@client, user)
          @client.contacts << user unless @client.contacts.include?(user)
          @message.to = user
        end
      end
    end

    def to_s
      "<Event Type=#{@event} Action=#{@action} Time=#{@time} Message=#{@message}>"
    end
  end
end
