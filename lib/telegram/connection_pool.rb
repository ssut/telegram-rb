module Telegram
  class ConnectionPool < Array
    include Logging

    attr_reader :size

    def initialize(size=10, &block)
      size.times do 
        self << block.call if block_given?
      end
    end

    def communicate(*messages, &block)
      begin
        acquire do |conn|
          conn.communicate(*messages, &block)
        end
      rescue Exception => e
        logger.error("Error occurred during the communicating: #{e.inspect} #{e.backtrace}")
      end

    end

    def acquire(&callback)
      acq = Proc.new {
        conn = self.find { |conn| conn.available? }
        if not conn.nil? and conn.connected?
          callback.call(conn)
        else
          logger.warning("Failed to acquire available connection, retry after 0.1 second")
          EM.add_timer(0.1, &acq)
        end
      }
      EM.add_timer(0, &acq)
    end
  end
end
