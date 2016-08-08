require 'ostruct'

module Telegram
  # Telegram client config
  #
  # Available options:
  #
  #   * daemon: path to telegram-cli binary
  #   * key: path to telegram-cli public key
  #   * sock: path to Unix domain socket that telegram-cli will listen to
  #   * size: connection pool size
  class Config
    extend Forwardable

    DEFAULT_OPTIONS = {
      daemon: 'bin/telegram',
      key: 'tg-server.pub',
      sock: 'tg.sock',
      size: 5
    }.freeze

    def_delegators :@options, :daemon, :daemon=, :key, :key=, :sock, :sock=,
                   :size, :size=, :profile, :profile=, :logger, :logger=,
                   :config_file, :config_file=

    def initialize(options = {})
      @options = OpenStruct.new(DEFAULT_OPTIONS.merge(options))
    end
  end
end
