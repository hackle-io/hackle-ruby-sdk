# frozen_string_literal: true

require 'hackle/client'
require 'hackle/config'
require 'hackle/version'

module Hackle

  #
  # Instantiates a Hackle client.
  #
  # @see Client#initialize
  #
  # @param sdk_key [String] The SDK key of your Hackle environment
  # @param options Optional parameters of configuration options
  #
  # @return [Client] The Hackle client instance.
  #
  def self.client(sdk_key:, **options)
    config = Config.new(options)
    sdk_info = SdkInfo.new(key: sdk_key)

    http_workspace_fetcher = HttpWorkspaceFetcher.new(config: config, sdk_info: sdk_info)
    polling_workspace_fetcher = PollingWorkspaceFetcher.new(config: config, http_fetcher: http_workspace_fetcher)

    event_dispatcher = EventDispatcher.new(config: config, sdk_info: sdk_info)
    event_processor = EventProcessor.new(config: config, event_dispatcher: event_dispatcher)

    polling_workspace_fetcher.start!
    event_processor.start!

    Client.new(
      config: config,
      workspace_fetcher: polling_workspace_fetcher,
      event_processor: event_processor,
      decider: Decider.new
    )
  end

  #
  # Instantiate a user to be used for the hackle sdk.
  #
  # The only required parameter is `id`, which must uniquely identify each user.
  #
  # @example
  #  Hackle.user(id: 'ae2182e0')
  #  Hackle.user(id: 'ae2182e0', app_version: '1.0.1', paying_customer: false)
  #
  # @param id [String] The identifier of the user. (e.g. device_id, account_id etc.)
  # @param properties Additional properties of the user. (e.g. app_version, membership_grade, etc.)
  #
  # @return [User] The configured user object.
  #
  def self.user(id:, **properties)
    User.new(id: id, properties: properties)
  end

  #
  # Instantiate an event to be used for the hackle sdk.
  #
  # The only required parameter is `key`, which must uniquely identify each event.
  #
  # @example
  #  Hackle.event(key: 'purchase')
  #  Hackle.event(key: 'purchase', value: 42000.0, app_version: '1.0.1', payment_method: 'CARD' )
  #
  # @param key [String] The unique key of the events.
  # @param value [Float] Optional numeric value of the events (e.g. purchase_amount, quantity, etc.)
  # @param properties Additional properties of the events (e.g. app_version, os_type, etc.)
  #
  # @return [Event] The configured event object.
  #
  def self.event(key:, value: nil, **properties)
    Event.new(key: key, value: value, properties: properties)
  end
end
