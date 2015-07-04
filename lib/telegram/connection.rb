module Telegram
  class Connection < EventMachine::Connection
    def initialize
      super
      @connected = false
      @on_connect = nil
      @on_disconnect = nil
      @callback = nil
    end

    def communicate(*messages, &callback)
      @callback = callback
      messages = messages.map { |m| escape(m) }.join << "\n"
      send_data(messages)
    end

    def on_connect=(block)
      @on_connect = block
    end

    def on_disconnect=(block)
      @on_disconnect = block
    end

    # @api private
    def connection_completed
      @connected = true
      @on_connect.call unless @on_connect.nil?
    end

    def unbind
      @connected = false
      @on_disconnect.call unless @on_disconnect.nil?
    end

    def connected?
      @connected
    end

    def receive_data(data)
      p data
      begin
        result = _receive_data(data)
      rescue
        result = nil
      end
      @callback.call(!result.nil?, result) unless @callback.nil?
    end

    protected
    def _receive_data(data)
      if data[0..6] == 'ANSWER '
        lf = data.index("\n") + 1
        lflf = data.index("\n\n", lf) - 1
        data = data[lf..lflf]
        data = Oj.load(data)
      end
      data
    end

    def escape(str)
      str.gsub(' ', '_ ')
    end
  end
end
