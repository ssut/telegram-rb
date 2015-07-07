module Telegram
  # Telegram API Implementation
  # 
  # @note You must avoid doing direct calls or initializes
  # @see Client
  # @version 0.1.0
  class API
    # Update user profile, contacts and chats
    #
    # @api private
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
          logger.info("Successfully loaded all information")
        else
          EM.next_tick(&check_done)
        end
      }
      EM.add_timer(0, &check_done)
    end

    # Update user profile
    #
    # @api private
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

    # Update user contacts
    #
    # @api private
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

    # Update user chats
    #
    # @api private
    def update_chats!
      assert!
      callback = Callback.new
      
      collected = 0
      collect_done = Proc.new do |id, data, count|
        collected += 1
        @chats << TelegramChat.new(self, data)
        callback.trigger(:success) if collected == count
      end
      collect = Proc.new do |id, count|
        @connection.communicate(['chat_info', "chat\##{id}"]) do |success, data|
          collect_done.call(id, data, count) if success
        end
      end

      @chats = []
      @connection.communicate('dialog_list') do |success, data|
        if success and data.class == Array
          chatsize = data.count { |chat| chat['type'] == 'chat' }
          data.each do |chat|
            if chat['type'] == 'chat'
              collect.call(chat['id'], chatsize)
            elsif chat['type'] == 'user'
              @chats << TelegramChat.new(self, chat)
            end
          end
        else
          raise "Couldn't fetch the dialog(chat) list."
        end
      end
      callback
    end

    # Send a message to specific user or chat
    #
    # @param [String] target Target to send a message
    # @param [String] text Message content to be sent
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The data of the request
    # @since [0.1.0]
    # @example
    #   telegram.msg('user#1234567', 'hello!') do |success, data|
    #     puts success # => true
    #     puts data # => {"event": "message", "out": true, ...}
    #   end
    def msg(target, text, &callback)
      assert!
      @connection.communicate(['msg', target, text], &callback)
    end

    # Add a user to the chat group
    #
    # @param [String] chat Target chat group to add a user
    # @param [String] user User who would be added
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.0]
    # @example
    #   telegram.chat_add_user('chat#1234567', 'user#1234567') do |success, data|
    #     puts success # => true
    #     puts data # => {"event": "service", ...}
    #   end
    def chat_add_user(chat, user, &callback)
      assert!
      @connection.communicate(['chat_add_user', chat, user], &callback)
    end

    # Remove a user from the chat group
    # You can leave a group by this method (Set a user identifier to your identifier)
    #
    # @param [String] chat Target chat group to remove a user
    # @param [String] user User who would be removed from the chat
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.0]
    # @example
    #   telegram.chat_del_user('chat#1234567', 'user#1234567') do |success, data|
    #     puts success # => true
    #     puts data # => {"event": "service", ...}
    #   end
    def chat_del_user(chat, user, &callback)
      assert!
      @connection.communicate(['chat_del_user', chat, user], &callback)
    end

    # Send typing signal to the chat
    #
    # @param [String] chat Target chat group to send typing signal
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.1]
    # @example
    #   telegram.send_typing('chat#1234567') do |success, data|
    #     puts success # => true
    #     puts data # => {"result": "SUCCESS"}
    #   end
    def send_typing(chat, &callback)
      assert!
      @connection.communicate(['send_typing', chat], &callback)
    end

    # Abort sendign typing signal
    #
    # @param [String] chat Target chat group to stop sending typing signal
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.1]
    # @example
    #   telegram.send_typing_abort('chat#1234567') do |success, data|
    #     puts success # => true
    #     puts data # => {"result": "SUCCESS"}
    #   end
    def send_typing_abort(chat, &callback)
      assert!
      @connection.communicate(['send_typing_abort', chat], &callback)
    end

    # Send a photo to the chat
    #
    # @param [String] chat Target chat group to send a photo
    # @param [String] path The path of the image you want to send
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.1]
    # @example
    #   telegram.send_photo('chat#1234567') do |success, data|
    #     puts "there was a problem during the sending" unless success
    #     puts success # => true
    #     puts data # => {"event": "message", "media": {"type": "photo", ...}, ...}
    #   end
    def send_photo(chat, path, &callback)
      assert!
      @connection.communicate(['send_photo', chat, path], &callback)
    end

    # Send a video to the chat
    #
    # @param [String] chat Target chat group to send a video
    # @param [String] path The path of the video you want to send
    # @param [Block] callback Callback block that will be called when finished
    # @yieldparam [Bool] success The result of the request (true or false)
    # @yieldparam [Hash] data The raw data of the request
    # @since [0.1.1]
    # @example
    #   telegram.send_photo('chat#1234567') do |success, data|
    #     puts "there was a problem during the sending" unless success
    #     puts success # => true
    #     puts data # => {"event": "message", "media": {"type": "video", ...}, ...}
    #   end
    def send_video(chat, path, &callback)
      assert!
      @connection.communicate(['send_video', chat, path], &callback)
    end

    protected
    # Check the availability of the telegram-cli daemon
    #
    # @since [0.1.0]
    # @api private
    def assert!
      raise "It appears that the connection to the telegram-cli is disconnected." unless connected?
    end
  end
end
