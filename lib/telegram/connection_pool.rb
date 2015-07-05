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
        acquire do |conn|
          conn.communicate(*messages, &block)
        end
      rescue Exception => e
      end

    end

    def acquire(&callback)
      acq = Proc.new {
        conn = self.find { |conn| conn.available? }
        if not conn.nil? and conn.connected?
          callback.call(conn)
        else
          EM.add_timer(0.1, &acq)
        end
      }
      EM.add_timer(0, &acq)
    end
  end
end
