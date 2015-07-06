module Telegram
  # Telegram-CLI Connection
  #
  # @note Don't make a connection directly to the telegram-cli
  # @see Client
  # @version 0.1.0
  class Connection < EM::Connection
    # Initialize connection
    #
    # @version 0.1.0
    def initialize
      super
      @connected = false
      @on_connect = nil
      @on_disconnect = nil
      @callback = nil
      @available = true
    end

    # @return [Bool] the availiability of current connection 
    def available?
      @available
    end

    # Communicate telegram-rb with telegram-cli connection
    #
    # @param [Array<String>] messages Messages that will be sent
    # @yieldparam [Block] callback Callback block that will be called when finished
    def communicate(*messages, &callback)
      @available = false
      @callback = callback
      messages = messages.each_with_index.map { |m, i|
        if i > 0
          m = "\"#{m}\""
        end
        m
      }.join(' ') << "\n"
      send_data(messages)
    end

    # Set a block that will be called when connected
    #
    # @param [Block] block
    def on_connect=(block)
      @on_connect = block
    end


    # Set a block that will be called when disconnected
    #
    # @param [Block] block
    def on_disconnect=(block)
      @on_disconnect = block
    end

    # This method will be called by EventMachine when connection completed
    #
    # @api private
    def connection_completed
      @connected = true
      @on_connect.call unless @on_connect.nil?
    end

    # This method will be called by EventMachine when connection unbinded
    #
    # @api private
    def unbind
      @connected = false
      @on_disconnect.call unless @on_disconnect.nil?
    end

    # @return [Bool] the availiability of current connection 
    def connected?
      @connected
    end

    # This method will be called by EventMachine when data arrived
    # then parse given data and execute callback method if exists 
    #
    # @api private
    def receive_data(data)
      begin
        result = _receive_data(data)
      rescue
        result = nil
      end
      @callback.call(!result.nil?, result) unless @callback.nil?
      @callback = nil
      @available = true
    end

    protected
    # Parse received data to correct json format and then convert to Ruby {Hash}
    #
    # @api private
    def _receive_data(data)
      if data[0..6] == 'ANSWER '
        lf = data.index("\n") + 1
        lflf = data.index("\n\n", lf) - 1
        data = data[lf..lflf]
        data = Oj.load(data)
      end
      data
    end
  end
end
