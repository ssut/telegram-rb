require 'ostruct'

module Telegram
  # Telegram client authorization properties
  #
  # Available options:
  #
  #   * phone_number: phone number which will be authorized
  #   * confirmation: proc which should return confirmation code received via
  #                   text message, or call
  #   * register(optional): hash with two options
  #     - :first_name: user first name
  #     - :last_name: user last name
  class AuthProperties
    extend Forwardable

    DEFAULT_OPTIONS = {
      confirmation: -> {},
      registration: {},
    }.freeze

    def_delegators :@options, :phone_number, :phone_number=, :confirmation,
                   :confirmation=, :registration= , :registration

    def initialize(options = {})
      @options = OpenStruct.new(DEFAULT_OPTIONS.merge(options))
    end

    def register?
      registration.include?(:first_name) &&
        registration.include?(:last_name)
    end

    def present?
      !phone_number.nil?
    end
  end
end
