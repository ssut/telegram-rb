module Telegram
  # Connection Pool
  #
  # @see Client
  # @version 0.1.0
  class ConnectionPool < Array
    include Logging

    # @return [Integer] Connection pool size, will be set when initialized
    attr_reader :size

    # Initialize ConnectionPool
    #
    # @param [Integer] size Connection pool size
    # @param [Block] block Create a connection in this block, have to pass a {Connection} object
    def initialize(size=10, &block)
      size.times do 
        self << block.call if block_given?
      end
    end

    # Communicate with acquired connection
    #
    # @see Connection
    # @param [Array<String>] messages Messages that will be sent
    # @param [Block] block Callback block that will be called when finished
    def communicate(*messages, &block)
      begin
        acquire do |conn|
          conn.communicate(*messages, &block)
        end
      rescue Exception => e
        logger.error("Error occurred during the communicating: #{e.inspect} #{e.backtrace}")
      end

    end

    # Acquire available connection
    #
    # @see Connection
    # @param [Block] callback This block will be called when successfully acquired a connection
    # @yieldparam [Connection] connection acquired connection
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
