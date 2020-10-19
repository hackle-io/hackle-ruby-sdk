module Hackle
  class Clients
    #
    # Instantiates a Hackle client.
    #
    # @param sdk_key [String] The SDK key of your Hackle environment.
    # @param config [Config] An optional client configuration
    #
    # @return [Client] The Hackle client instance.
    #
    def self.create(sdk_key, config = Config.new)
      sdk_info = SdkInfo.new(sdk_key)

      http_workspace_fetcher = HttpWorkspaceFetcher.new(config, sdk_info)
      polling_workspace_fetcher = PollingWorkspaceFetcher.new(config, http_workspace_fetcher)

      event_dispatcher = EventDispatcher.new(config, sdk_info)
      event_processor = EventProcessor.new(config, event_dispatcher)

      polling_workspace_fetcher.start!
      event_processor.start!

      Client.new(config, polling_workspace_fetcher, event_processor, Decider.new)
    end
  end
end
