module Telegram
  class Callback
    def initialize
      @success = nil
      @fail = nil
    end

    def callback(&cb)
      @success = cb
    end

    def errback(&cb)
      @fail = cb
    end

    def trigger(type = :success)
      case type
      when :success
        @success.call
      when :fail
        @fail.call
      end
    end
  end
end
