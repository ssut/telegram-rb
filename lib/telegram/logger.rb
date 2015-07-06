require 'logger'

module Telegram
  # Module for logging:
  # You can use logger using this module
  # @example
  #   class Klass
  #     include Telegram::Logging
  #     def initialize
  #       logger.info("Initialized!") # => [1970-01-01 00:00:00] INFO  (Klass): Initialized!
  #     end
  #   end
  #
  # @since [0.1.0]
  module Logging
    # Get logger, will be initialized within a class
    #
    # @return [Logger] logger object
    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    @loggers = {}
    class << self
      # Logger pool, acquire logger from the logger table or not, create a new logger
      #
      # @param [String] klass Class name
      # @return [Logger] Logger instance
      # @api private
      def logger_for(klass)
        @loggers[klass] ||= configure_logger_for(klass)
      end

      # Create a new logger
      #
      # @param [String] klass Class name
      # @return [Logger] Logger instance
      # @api private
      def configure_logger_for(klass)
        logger = Logger.new(STDOUT)
        logger.progname = klass
        logger.level = Logger::DEBUG
        logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
          blanks = severity.size == 4 ? '  ' : ' '
          "[#{date_format}] #{severity}#{blanks}(#{progname}): #{msg}\n"
        end

        logger
      end
    end
  end
end
