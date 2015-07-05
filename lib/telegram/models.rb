module Telegram
  class TelegramBase
    attr_reader :client
    attr_reader :id

    def send_message(text, refer)

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

    def update

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

    def update

    end

    def to_s
      "<TelegramContact #{@name}(#{@id}) username=#{@username}>"
    end
  end

  class TelegramMessage
  end
end
