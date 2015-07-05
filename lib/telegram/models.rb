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
    attr_reader :phone
    attr_reader :members

    def initialize(client, chat)
      @client = client
      @chat = chat

      @id = chat['id']
      @title = chat.has_key?('title') ? chat['title'] : chat['print_name']
      @type = chat['type']

      @members = []
      chat['members'].each { |user|
        @members << TelegramContact.new(client, user)
      } if chat.has_key?('members')
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
end
