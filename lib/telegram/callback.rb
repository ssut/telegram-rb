module Telegram
  # Callback class for em-synchrony
  #
  # @note You don't need to make this callback object without when it needed
  # @see API
  # @version 0.1.0
  class Callback
    # @return [Object] Data
    attr_reader :data

    def initialize
      @success = nil
      @fail = nil
      @data = nil
    end

    # Set a callback to be called when succeed
    #
    # @param [Block] cb
    def callback(&cb)
      @success = cb
    end

    # Set a callback to be called when failed
    #
    # @param [Block] cb
    def errback(&cb)
      @fail = cb
    end

    # Trigger either success or error actions with data
    # 
    # @param [Symbol] type :success or :fail
    # @param [Object] data
    def trigger(type = :success, data = nil)
      @data = data
      case type
      when :success
        @success.call
      when :fail
        @fail.call
      end
    end
  end
end
