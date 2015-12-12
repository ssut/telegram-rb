module Telegram
  # Base class for Telegram models
  #
  # @see TelegramChat
  # @see TelegramRoom
  # @since [0.1.0]
  class TelegramBase
    include Logging

    # @return [Client] Root client instance
    attr_reader :client

    # @return [Integer] Identifier
    attr_reader :id

    # Return an instance if exists, or else create a new instance and return
    #
    # @param [Client] client Root client instance
    # @param [Integer] raw Raw data on either of telegram objects
    # @since [0.1.0]
    def self.pick_or_new(client, raw)
      # where to search for
      where = if self == TelegramChat
        client.chats
      elsif self == TelegramContact
        client.contacts
      end

      # pick a first item if exists, or else create
      where.find { |obj| obj.id == raw['peer_id'] } or self.new(client, raw)
    end

    # Convert to telegram-cli target format from {TelegramChat} or {TelegramContact}
    #
    # @since [0.1.1]
    def targetize
      @type == 'encr_chat' ? @title : to_tg
    end

    # Execute a callback block with failure result
    #
    # @since [0.1.1]
    # @api private
    def fail_back(&callback)
      callback.call(false, {}) unless callback.nil?
    end

    # Send typing signal
    #
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.1]
    def send_typing(&callback)
      if @type == 'encr_chat'
        logger.warn("Currently telegram-cli has a bug with send_typing, then prevent this for safety")
        return
      end
      @client.send_typing(targetize, &callback)
    end

    # Abort sending typing signal
    #
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.1]
    def send_typing_abort(&callback)
      if @type == 'encr_chat'
        logger.warn("Currently telegram-cli has a bug with send_typing, then prevent this for safety")
        return
      end
      @client.send_typing_abort(targetize, &callback)
    end

    # Send a message with given text
    #
    # @param [String] text text you want to send for
    # @param [TelegramMessage] refer referrer of the method call
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.0]
    def send_message(text, refer, &callback)
      @client.msg(targetize, text, &callback)
    end

    # @abstract Send a sticker
    def send_sticker()

    end

    # Send an image
    #
    # @param [String] path The absoulte path of the image you want to send
    # @param [TelegramMessage] refer referral of the method call
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.1]
    def send_image(path, refer, &callback)
      if @type == 'encr_chat'
        logger.warn("Currently telegram-cli has a bug with send_typing, then prevent this for safety")
        return
      end
      fail_back(&callback) if not File.exist?(path)
      @client.send_photo(targetize, path, &callback)
    end

    # Send an image with given url, not implemen
    #
    # @param [String] url The URL of the image you want to send
    # @param [TelegramMessage] refer referral of the method call
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.1]
    def send_image_url(url, opt, refer, &callback)
      begin
        opt = {} if opt.nil?
        http = EM::HttpRequest.new(url, :connect_timeout => 2, :inactivity_timeout => 5).get opt
        file = Tempfile.new(['image', 'jpg'])
        http.stream { |chunk|
          file.write(chunk)
        }
        http.callback {
          file.close
          type = FastImage.type(file.path)
          if %i(jpeg png gif).include?(type)
            send_image(file.path, refer, &callback)
          else
            fail_back(&callback)
          end
        }
      rescue Exception => e
        logger.error("An error occurred during the image downloading: #{e.inspect} #{e.backtrace}")
        fail_back(&callback)
      end
    end

    # Send a video
    #
    # @param [String] path The absoulte path of the video you want to send
    # @param [TelegramMessage] refer referral of the method call
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.1]
    def send_video(path, refer, &callback)
      fail_back(&callback) if not File.exist?(path)
      @client.send_video(targetize, path, &callback)
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

    # Create a new chat instance
    #
    # @param [Client] client Root client instance
    # @param [Integer] chat Raw chat data
    # @since [0.1.0]
    def initialize(client, chat)
      @client = client
      @chat = chat

      @id = chat['peer_id']
      @name = @title = chat.has_key?('title') ? chat['title'] : chat['print_name']
      @type = chat['peer_type']

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
      @client.chat_del_user(self, @client.profile.to_tg)
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

    # @return [String] The username of the contact
    attr_reader :username

    # @return [Array<TelegramContact>] The phone number of the contact
    attr_reader :phone

    # @return [String] The type of the contact # => "user"
    attr_reader :type

    # Create a new contact instance
    #
    # @param [Client] client Root client instance
    # @param [Integer] contact Raw chat contact
    # @since [0.1.0]
    def initialize(client, contact)
      @client = client
      @contact = contact

      @id = contact['peer_id']
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

    # @return [String] Content type
    attr_reader :content_type

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
    # @param [Block] callback Callback block that will be called when finished
    def reply_user(type, content, &callback)

    end

    # Reply a message to the chat
    #
    # @param [Symbol] type Type of the message (either of :text, :sticker, :image)
    # @param [String] content Content to send a message
    # @param [TelegramChat] target Specify a TelegramChat to send
    # @param [TelegramContact] target Specify a TelegramContact to send
    # @param [Block] callback Callback block that will be called when finished
    # @since [0.1.0]
    def reply(type, content, target=nil, &callback)
      target = @target if target.nil?

      case type
      when :text
        target.send_message(content, self, &callback)
      when :image
        option = nil
        content, option = content if content.class == Array
        if content.include?('http')
          target.method(:send_image_url).call(content, option, self, &callback)
        else
          target.method(:send_image).call(content, self, &callback)
        end
      when :video
        target.send_video(content, self, &callback)
      end
    end

    def members
      contact_list = []
      if @target.class == TelegramContact
        contact_list << @target
      else
        contact_list = @target.members
      end

      contact_list
    end

    # Convert {TelegramMessage} instance to the string format
    #
    # @return [String]
    def to_s
      "<TelegramMessage id=#{@id} raw=#{@raw} time=#{@time} user=#{@user} target=#{@target} raw_target=#{@raw_target}>"
    end
  end
end
