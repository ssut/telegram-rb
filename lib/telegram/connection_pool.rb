module Telegram
  class ConnectionPool < Array
    attr_reader :size

    def initialize(size=5, &block)
      size.times do 
        self << block.call if block_given?
      end
    end

    def communicate(*messages, &block)
      begin
        conn = acquire
        conn.communicate(*messages, &block)
      rescue Exception => e
      end

    end

    def acquire
      conn = self.find { |conn| conn.available? }
      if not conn.nil? and conn.connected?
        return conn
      else
        EM.next_tick(&acquire)
      end
    end

    def release

    end
  end
end
