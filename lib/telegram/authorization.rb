module Telegram
  class Authorization
    def initialize(std_in_out, properties, logger)
      @std_in_out = std_in_out
      @properties = properties
      @logger = logger
    end

    def perform
      stdout_log = ''

      # there is no success auth message from telegram-cli to stdou as result
      # no way detect finish of authorization or registration process (after
      # success auth message will be added to telegram-cli, watcher should be removed)
      watcher = Watcher.new do
        std_in_out.puts('get_self')
        logger.info 'Authorization: watcher fired get_self'
      end

      # low-level read of stdout which mean that we receive data by chuncks
      while (data = std_in_out.sysread(1024))
        watcher.stop
        stdout_log << data

        case stdout_log
        when /phone number:/
          stdout_log = ''
          handle_phone_number
        when /code \('CALL' for phone code\):/
          stdout_log = ''
          handle_confirmation_code
        when /register \(Y\/n\):/
          stdout_log = ''
          handle_registration
        when /"phone": "#{properties.phone_number}"/
          logger.info 'Authorization: successfully completed'
          return true
        else
          # ping telegram-cli after stdout is inactive 2 sec (expects that
          # there is no bigger delay between stdout and next stdin request)
          watcher.call_after(2)
        end
      end
    end

    private

    attr_accessor :std_in_out, :properties, :logger

    def handle_phone_number
      raise 'Incorrect phone number' if @_phone_number_triggered
      @_phone_number_triggered = true

      std_in_out.puts(properties.phone_number)
      logger.info "Authorization: sent phone number (#{properties.phone_number})"
    end

    def handle_confirmation_code
      raise 'Incorrect confirmation code' if @_confirmation_triggered
      @_confirmation_triggered = true

      logger.info 'Authorization: retrieving confirmation code'
      confirmation_code = properties.confirmation.call
      std_in_out.puts(confirmation_code)
      logger.info "Authorization: sent confirmation code (#{confirmation_code})"
    end

    def handle_registration
      raise 'Registration required' unless properties.register?
      raise 'Incorrect first or last name' if @_registration_triggered
      @_registration_triggered = true

      std_in_out.puts('Y')
      std_in_out.puts(properties.registration[:first_name])
      std_in_out.puts(properties.registration[:last_name])
      logger.info "Authorization: sent registration data (#{properties.registration.inspect})"
    end
  end

  class Watcher
    def initialize(&block)
      @thread = nil
      @block = block
    end

    def call_after(sec)
      stop
      @thread = Thread.new { sleep(sec); @block.call }
    end

    def stop
      @thread.exit if @thread && @thread.alive?
    end
  end
end
