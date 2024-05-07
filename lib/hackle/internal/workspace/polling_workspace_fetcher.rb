# frozen_string_literal: true

require 'hackle/internal/logger/logger'
require 'hackle/internal/workspace/workspace_fetcher'

module Hackle
  class PollingWorkspaceFetcher
    include WorkspaceFetcher
    # @param http_workspace_fetcher [HttpWorkspaceFetcher]
    # @param scheduler [Scheduler]
    # @param polling_interval_seconds [Float]
    def initialize(http_workspace_fetcher:, scheduler:, polling_interval_seconds:)
      # @type [HttpWorkspaceFetcher]
      @http_workspace_fetcher = http_workspace_fetcher

      # @type [Scheduler]
      @scheduler = scheduler

      # @type [Float]
      @polling_interval_seconds = polling_interval_seconds

      # @type [ScheduledJob, nil]
      @polling_job = nil

      # @type [Workspace, nil]
      @workspace = nil
    end

    # @return [Workspace, nil]
    def fetch
      @workspace
    end

    def start
      return unless @polling_job.nil?

      poll
      @polling_job = @scheduler.schedule_periodically(@polling_interval_seconds, -> { poll })
    end

    def stop
      @polling_job&.cancel
      @polling_job = nil
    end

    def resume
      @polling_job&.cancel
      @polling_job = @scheduler.schedule_periodically(@polling_interval_seconds, -> { poll })
    end

    private

    def poll
      workspace = @http_workspace_fetcher.fetch_if_modified
      return if workspace.nil?

      @workspace = workspace
    rescue => e
      Log.get.error { "Failed to poll Workspace: #{e.inspect}" }
    end
  end
end
