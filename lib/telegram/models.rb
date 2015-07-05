module Telegram
  class TelegramBase
    attr_reader :client
    attr_reader :id

    def send_message(text, refer)
      target = case @type
      when 'encr_chat'
        "#{@title}"
      else
        "#{@type}\##{@id}"
      end
      @client.msg(target, text)
    end

    def send_sticker()

    end

    def send_image(path, refer, &callback)

    end

    def send_image_url(url, refer, &callback)

    end
  end

  class TelegramChat < TelegramBase
    attr_reader :name
    attr_reader :members
    attr_reader :type

    def self.pick_or_new(client, chat)
      ct = client.chats.find { |c| c.id == chat['id'] }
      return ct unless ct.nil?
      TelegramChat.new(client, chat)
    end

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

    def leave

    end

    def to_s
      "<TelegramChat #{@title}(#{@type}\##{@id}) members=#{@members.size}>"
    end
  end

  class TelegramContact < TelegramBase
    attr_reader :name
    attr_reader :phone
    attr_reader :type

    def self.pick_or_new(client, contact)
      ct = client.contacts.find { |c| c.id == contact['id'] }
      return ct unless ct.nil?
      TelegramContact.new(client, contact)
    end

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

    def rooms

    end

    def to_s
      "<TelegramContact #{@name}(#{@id}) username=#{@username}>"
    end
  end

  class TelegramMessage
    # @return [Telegram]
    attr_reader :client

    # @return [String]
    attr_reader :raw

    # @return [Integer]
    attr_reader :id

    # @return [Time]
    attr_reader :time

    # @return [TelegramContact] The user who sent this message
    attr_reader :user

    # targets to send a message
    attr_reader :raw_target
    attr_reader :target

    # @return [TelegramChat]
    attr_reader :chat

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

    def reply_user(type, content)

    end

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
