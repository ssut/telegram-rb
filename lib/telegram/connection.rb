module Telegram
  class Connection < EventMachine::Connection
    def initialize
      super
      @connected = false
      @on_connect = nil
      @callback = nil
    end

    def communicate(*messages, &callback)
      messages = messages.map { |m| escape(m) }.join
      messages << "\n"

      send_data(messages)
      @callback = callback
    end

    def on_connect=(block)
      @on_connect = block
    end

    def connected?
      @connected
    end

    # @api private
    def connection_completed
      @connected = true
      @on_connect.call
    end

    def receive_data(data)
      begin
        _receive_data(data)
      rescue

      end
    end

    protected
    def _receive_data(data)
      if data[0..6] == 'ANSWER '
        lf = data.index("\n") + 1
        lflf = data.index("\n\n", lf) - 1
        data = data[lf..lflf]
        data = Oj.load(data)
        p data
      end
    end

    def escape(str)
      str.gsub(' ', '_ ')
    end
  end
end
