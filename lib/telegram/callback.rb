module Telegram
  class Callback
    attr_reader :data

    def initialize
      @success = nil
      @fail = nil
      @data = nil
    end

    def callback(&cb)
      @success = cb
    end

    def errback(&cb)
      @fail = cb
    end

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
