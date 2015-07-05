require 'logger'

module Telegram
  module Logging
    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    @loggers = {}
    class << self
      def logger_for(klass)
        @loggers[klass] ||= configure_logger_for(klass)
      end

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
