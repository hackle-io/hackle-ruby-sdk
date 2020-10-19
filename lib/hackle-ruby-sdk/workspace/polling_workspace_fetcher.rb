require 'concurrent'

module Hackle
  class PollingWorkspaceFetcher

    DEFAULT_POLLING_INTERVAL = 10

    def initialize(config, http_fetcher)
      @logger = config.logger
      @http_fetcher = http_fetcher
      @current_workspace = Concurrent::AtomicReference.new
      @task = Concurrent::TimerTask.new(execution_interval: DEFAULT_POLLING_INTERVAL) { poll }
      @running = false
    end

    def fetch
      @current_workspace.get
    end

    def start!
      return if @running

      poll
      @task.execute
      @running = true
    end

    def stop!
      return unless @running

      @task.shutdown
      @running = false
    end

    def poll
      workspace = @http_fetcher.fetch
      @current_workspace.set(workspace)
    rescue => e
      @logger.error { "Failed to poll Workspace: #{e.inspect}" }
    end
  end
end
