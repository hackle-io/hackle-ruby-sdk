# frozen_string_literal: true

require 'rspec'
require 'hackle/internal/workspace/workspace'
require 'hackle/internal/workspace/polling_workspace_fetcher'
require 'hackle/internal/concurrent/schedule/timer_scheduler'

module Hackle
  describe PollingWorkspaceFetcher do
    before do
      @http_workspace_fetcher = double('Hackle::HttpWorkspaceFetcher')
      allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(nil)
    end

    def fetcher(http_workspace_fetcher: nil, scheduler: TimerScheduler.new, polling_interval_seconds: 10.0)
      PollingWorkspaceFetcher.new(
        http_workspace_fetcher: http_workspace_fetcher || @http_workspace_fetcher,
        scheduler: scheduler,
        polling_interval_seconds: polling_interval_seconds
      )
    end

    describe 'fetch' do
      it 'when before poll then return none' do
        sut = fetcher
        actual = sut.fetch
        expect(actual).to be_nil
      end

      it 'when failed to poll then return nil' do
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_raise('Fail')
        sut = fetcher

        sut.start
        actual = sut.fetch

        expect(actual).to be_nil
      end

      it 'when workspace is fetched then return workspace' do
        workspace = Workspace.create
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(workspace)
        sut = fetcher

        sut.start

        actual = sut.fetch

        expect(actual).to eq(workspace)
      end
    end

    describe 'poll' do
      it 'failed to poll' do
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_raise('Fail')
        sut = fetcher

        sut.start
        actual = sut.fetch

        expect(actual).to be_nil
      end

      it 'success to poll' do
        workspace = Workspace.create
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(workspace)
        sut = fetcher

        sut.start
        actual = sut.fetch

        expect(actual).to eq(workspace)
      end

      it 'workspace not modified' do
        workspace = Workspace.create
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(workspace, nil, nil, nil, nil)
        sut = fetcher(polling_interval_seconds: 0.1)

        sut.start
        sleep 0.35
        actual = sut.fetch

        expect(actual).to eq(workspace)
      end
    end

    describe 'start' do
      it 'poll' do
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(Workspace.create)
        sut = fetcher

        sut.start
        expect(sut.fetch).not_to be_nil
      end

      it 'start scheduling' do
        allow(@http_workspace_fetcher).to receive(:fetch_if_modified).and_return(
          Workspace.create,
          Workspace.create,
          Workspace.create,
          Workspace.create,
          Workspace.create,
          Workspace.create
        )

        sut = fetcher(polling_interval_seconds: 0.1)
        sut.start
        sleep 0.55

        expect(sut.fetch).not_to be_nil
        expect(@http_workspace_fetcher).to have_received(:fetch_if_modified).exactly(6).times

        sut.stop
      end
    end
  end
end
