module Telegram
  # Base class for Telegram models
  #
  # @see TelegramChat
  # @see TelegramRoom
  # @since [0.1.0]
  class TelegramBase
    # @return [Client] Root client instance
    attr_reader :client

    # @return [Integer] Identifier
    attr_reader :id

    # Send a message with given text
    #
    # @param [String] text text you want to send for
    # @param [TelegramMessage] refer referrer of the method call
    # @since [0.1.0]
    def send_message(text, refer)
      target = case @type
      when 'encr_chat'
        "#{@title}"
      else
        to_tg
      end
      @client.msg(target, text)
    end

    # @abstract Send a sticker
    def send_sticker()

    end

    # @abstract Send an image
    #
    # @param [String] path The absoulte path of the image you want to send
    # @param [TelegramMessage] refer referral of the method call
    # @param [Block] callback Callback block that will be called when finished
    def send_image(path, refer, &callback)

    end

    # @abstract Send an image with given url, not implemen
    #
    # @param [String] url The URL of the image you want to send
    # @param [TelegramMessage] refer referral of the method call
    # @param [Block] callback Callback block that will be called when finished
    def send_image_url(url, refer, &callback)

    end
  end

  # Telegram Chat Model
  #
  # @see TelegramBase
  # @since [0.1.0]
  class TelegramChat < TelegramBase
    # @return [String] The name of the chat
    attr_reader :name

    # @return [Array<TelegramContact>] The members of the chat
    attr_reader :members

    # @return [String] The type of the chat (chat, encr_chat, user and etc)
    attr_reader :type

    # Return an instance if exists, or else create a new instance and return
    #
    # @param [Client] client Root client instance
    # @param [Integer] chat Raw chat data
    # @since [0.1.0]
    def self.pick_or_new(client, chat)
      ct = client.chats.find { |c| c.id == chat['id'] }
      return ct unless ct.nil?
      TelegramChat.new(client, chat)
    end

    # Create a new chat instance
    #
    # @param [Client] client Root client instance
    # @param [Integer] chat Raw chat data
    # @since [0.1.0]
    def initialize(client, chat)
      @client = client
      @chat = chat

      @id = chat['id']
      @title = chat.has_key?('title') ? chat['title'] : chat['print_name']
      @type = chat['type']

      @members = []
      if chat.has_key?('members')
        chat['members'].each { |user|
          @members << TelegramContact.pick_or_new(client, user)
        }
      elsif @type == 'user' and chat['user']
        @members << TelegramContact.pick_or_new(client, chat)
      end
    end

    # Leave from current chat
    #
    # @since [0.1.0]
    def leave!
      @client.chat_del_user(self, @client.profile)
    end

    # @return [String] A chat identifier formatted with type
    def to_tg
      "#{@type}\##{@id}"
    end

    # Convert {Event} instance to the string format
    #
    # @return [String]
    def to_s
      "<TelegramChat #{@title}(#{@type}\##{@id}) members=#{@members.size}>"
    end
  end

  # Telegram Contact Model
  #
  # @see TelegramBase
  # @since [0.1.0]
  class TelegramContact < TelegramBase
    # @return [String] The name of the contact
    attr_reader :name

    # @return [Array<TelegramContact>] The phone number of the contact
    attr_reader :phone

    # @return [String] The type of the contact # => "user"
    attr_reader :type

    # Return an instance if exists, or else create a new instance and return
    #
    # @param [Client] client Root client instance
    # @param [Integer] contact Raw contact data
    # @since [0.1.0]
    def self.pick_or_new(client, contact)
      ct = client.contacts.find { |c| c.id == contact['id'] }
      return ct unless ct.nil?
      TelegramContact.new(client, contact)
    end

    # Create a new contact instance
    #
    # @param [Client] client Root client instance
    # @param [Integer] contact Raw chat contact
    # @since [0.1.0]
    def initialize(client, contact)
      @client = client
      @contact = contact

      @id = contact['id']
      @type = 'user'
      @username = contact.has_key?('username') ? contact['username'] : ''
      @name = contact['print_name']
      @phone = contact.has_key?('phone') ? contact['phone'] : ''

      @client.contacts << self unless @client.contacts.include?(self)
    end

    # @return [Array<TelegramChat>] Chats that contact participates
    # @since [0.1.0]
    def chats
      @client.chats.select { |c| c.member.include?(self) }
    end

    # @return [String] A chat identifier formatted with type
    def to_tg
      "#{@type}\##{@id}"
    end

    # Convert {Event} instance to the string format
    #
    # @return [String]
    def to_s
      "<TelegramContact #{@name}(#{@id}) username=#{@username}>"
    end
  end

  # Telegram Message Model
  #
  # @see Event
  # @since [0.1.0]
  class TelegramMessage
    # @return [Client] Root client instance
    attr_reader :client

    # @return [String] Raw string of the text
    attr_reader :raw

    # @return [Integer] Message identifier
    attr_reader :id

    # @return [Time] Time message received
    attr_reader :time

    # @return [TelegramContact] The contact who sent this message
    attr_reader :user

    # @return [String] 
    attr_reader :raw_target

    # @return [TelegramChat] if you were talking in a chat group
    # @return [TelegramContact] if you were talking with contact
    attr_reader :target

    # Create a new tgmessage instance
    #
    # @param [Client] client Root client instance
    # @param [Event] event Root event instance
    # @see Event
    # @since [0.1.0]
    def initialize(client, event)
      @event = event
      
      @id = event.id
      @raw = event.message.text
      @time = event.time
      @content_type = event.message.type

      @raw_sender = event.message.raw_from
      @raw_receiver = event.message.raw_to

      @user = @sender = event.message.from
      @receiver = event.message.to

      @target = case @receiver.type
      when 'user'
        @sender
      when 'chat', 'encr_chat'
        @receiver
      end
    end

    # @abstract Reply a message to the sender (peer to peer)
    #
    # @param [Symbol] type Type of the message (either of :text, :sticker, :image)
    # @param [String] content Content to send a message
    def reply_user(type, content)

    end

    # Reply a message to the chat
    #
    # @param [Symbol] type Type of the message (either of :text, :sticker, :image)
    # @param [String] content Content to send a message
    # @since [0.1.0]
    def reply(type, content, target=nil, &cb)
      target = @target if target.nil?
      if type == :text
        target.send_message(content, self)
      elsif type == :sticker 
      elsif type == :image
      end
    end
  end
end
