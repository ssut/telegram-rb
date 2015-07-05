module Telegram
  class API
    def update!(&cb)
      done = false
      EM.synchrony do
        multi = EM::Synchrony::Multi.new
        multi.add :profile, update_profile!
        multi.add :contacts, update_contacts!
        multi.add :chats, update_chats!
        multi.perform
        done = true
      end

      check_done = Proc.new {
        if done
          @starts_at = Time.now
          cb.call unless cb.nil?
        else
          EM.next_tick(&check_done)
        end
      }
      EM.add_timer(0, &check_done)
    end

    def update_profile!
      assert!
      callback = Callback.new
      @profile = nil
      @connection.communicate('get_self') do |success, data|
        if success
          callback.trigger(:success)
          contact = TelegramContact.pick_or_new(self, data)
          @contacts << contact unless self.contacts.include?(contact)
          @profile = contact
        else
          raise "Couldn't fetch the user profile."
        end
      end
      callback
    end

    def update_contacts!
      assert!
      callback = Callback.new
      @contacts = []
      @connection.communicate('contact_list') do |success, data|
        if success and data.class == Array
          callback.trigger(:success)
          data.each { |contact|
            contact = TelegramContact.pick_or_new(self, contact)
            @contacts << contact unless self.contacts.include?(contact)
          }
        else
          raise "Couldn't fetch the contact list."
        end
      end
      callback
    end

    def update_chats!
      assert!
      callback = Callback.new
      collected = 0

      collect_done = Proc.new { |id, data, count|
        collected += 1
        @chats << TelegramChat.new(self, data)
        callback.trigger(:success) if collected == count
      }
      collect = Proc.new { |id, count|
        @connection.communicate(['chat_info', "chat\##{id}"]) do |success, data|
          collect_done.call(id, data, count) if success
        end
      }

      @chats = []
      @connection.communicate('dialog_list') do |success, data|
        if success and data.class == Array
          chatsize = data.count { |chat| chat['type'] == 'chat' }
          data.each { |chat|
            if chat['type'] == 'chat'
              collect.call(chat['id'], chatsize)
            elsif chat['type'] == 'user'
              @chats << TelegramChat.new(self, chat)
            end
          }
        else
          raise "Couldn't fetch the dialog(chat) list."
        end
      end
      callback
    end

    def msg(target, text, &callback)
      assert!
      @connection.communicate(['msg', target, text], &callback)
    end

    protected
    def assert!
      raise "It appears that the connection to the telegram-cli is disconnected." unless connected?
    end
  end
end
