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
  # @param config [Config] An optional client configuration
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
end
