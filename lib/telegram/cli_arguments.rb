module Telegram
  # Command line arguments for telegram-cli
  class CLIArguments
    def initialize(config)
      @config = config
    end

    def to_s
      [
        disable_colors,
        rsa_key,
        disable_names,
        wait_dialog_list,
        udp_socket,
        json,
        disable_readline,
        profile
      ].compact.join(' ')
    end

    private

    def disable_colors
      '-C'
    end

    def rsa_key
      "-k '#{@config.key}'"
    end

    def disable_names
      '-I'
    end

    def wait_dialog_list
      '-W'
    end

    def udp_socket
      "-S '#{@config.sock}'"
    end

    def json
      '--json'
    end

    def disable_readline
      '-R'
    end

    def profile
      "-p #{@config.profile}" if @config.profile
    end
  end
end
