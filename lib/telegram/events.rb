module Telegram
  # Define Event Types
  #
  # @see Event
  # @since [0.1.0]
  module EventType
    # Unknown Event
    # @since [0.1.0]
    UNKNOWN_EVENT = -1
    # Service
    # @since [0.1.0]
    SERVICE = 0
    # Receive Message
    # @since [0.1.0]
    RECEIVE_MESSAGE = 1
    # Send Message
    # @since [0.1.0]
    SEND_MESSAGE = 2
    # Online Status Changes
    # @since [0.1.0]
    ONLINE_STATUS = 3
  end

  # Define Action Types
  #
  # @see Event
  # @since [0.1.0]
  module ActionType
    # Unknown Action
    # @since [0.1.0]
    UNKNOWN_ACTION = -1
    # No Action
    # @since [0.1.0]
    NO_ACTION = 0
    # Adde a user to the chat
    # @since [0.1.0]
    CHAT_ADD_USER = 1
    # Remove a user from the chat
    # @since [0.1.0]
    CHAT_DEL_USER = 2
    # Rename title of the chat
    # @since [0.1.0]
    CHAT_RENAME = 3
    # Create group chat
    # @since [0.1.0]
    CREATE_GROUP_CHAT = 4

    ADD_CONTACT = 5
  end

  # Message object belong to {Event} class instance
  #
  # @see Event
  # @since [0.1.0]
  class Message < Struct.new(:id, :text, :type, :from, :from_type, :raw_from, :to, :to_type, :raw_to)
    # @!attribute id
    #   @return [Number] Message Identifier
    attr_accessor :id

    # @!attribute text
    #   @return [String] The text of the message
    attr_accessor :text

    # @!attribute type
    #   @return [String] The type of the message (either of text, photo, video or etc)
    attr_accessor :type

    # @!attribute from
    #   @return [TelegramContact] The sender of the message
    attr_accessor :from

    # @!attribute from_type
    #   @return [String] The type of the sender
    attr_accessor :from_type

    # @!attribute raw_from
    #   @return [String] Raw identifier string of the sender
    attr_accessor :raw_from

    # @!attribute to
    #   @return [TelegramChat] If you receive a message in the chat group
    #   @return [TelegramContact] If you receive a message in the chat with one contact
    attr_accessor :to

    # @!attribute to_type
    #   @return [String] The type of the receiver
    attr_accessor :to_type

    # @!attribute raw_to
    #   @return [String] Raw identifier string of the receiver
    attr_accessor :raw_to
  end

  # Event object, will be created in the process part of {Client}
  #
  # @see Client
  # @since [0.1.0]
  class Event
    # @return [Number] Event identifier
    attr_reader :id

    # @return [EventType] Event type, created from given data
    attr_reader :event

    # @return [ActionType] Action type, created from given data
    attr_reader :action

    # @return [Time] Time event received
    attr_reader :time

    # @return [Message] Message object, created from given data
    attr_reader :message

    # @return [TelegramMessage] Telegram message object, created from {Message}
    attr_reader :tgmessage

    # Create a new {Event} instance
    #
    # @param [Client] client Root client instance
    # @param [EventType] event Event type
    # @param [ActionType] action Action type
    # @param [Hash] data Raw data
    # @since [0.1.0]
    def initialize(client, event = EventType::UNKNOWN_EVENT, action = ActionType::NO_ACTION, data = {})
      @client = client
      @id = data.respond_to?(:[]) ? data['id'] : ''
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

    # Process raw data in which event type is service given.
    #
    # @return [void]
    # @api private
    def format_service

    end

    # Process raw data in which event type is message given.
    #
    # @return [void]
    # @api private
    def format_message
      message = Message.new

      message.id = @id
      message.text = @raw_data['text'] ||= ''
      media = @raw_data['media']
      message.type = media ? media['type'] : 'text'
      message.raw_from = @raw_data['from']['peer_id']
      message.from_type = @raw_data['from']['peer_type']
      message.raw_to = @raw_data['to']['peer_id']
      message.to_type = @raw_data['to']['peer_type']

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
        type = @raw_data['to']['peer_type']
        case type
        when 'chat', 'encr_chat'
          chat = TelegramChat.pick_or_new(@client, @raw_data['to'])
          @client.chats << chat unless @client.chats.include?(chat)
          if type == 'encr_chat' then
            @message.to = chat
          else
            @message.from = chat
          end
        when 'user'
          user = TelegramContact.pick_or_new(@client, @raw_data['to'])
          @client.contacts << user unless @client.contacts.include?(user)
          @message.to = user
        end
      end
    end

    # Convert {Event} instance to the string format
    #
    # @return [String]
    def to_s
      "<Event Type=#{@event} Action=#{@action} Time=#{@time} Message=#{@tgmessage}>"
    end
  end
end
