require 'hackle-ruby-sdk/decision/bucketer'
require 'hackle-ruby-sdk/decision/decider'

require 'hackle-ruby-sdk/event/event'
require 'hackle-ruby-sdk/event/event_dispatcher'
require 'hackle-ruby-sdk/event/event_processor'

require 'hackle-ruby-sdk/http/http'

require 'hackle-ruby-sdk/model/bucket'
require 'hackle-ruby-sdk/model/event_type'
require 'hackle-ruby-sdk/model/experiment'
require 'hackle-ruby-sdk/model/slot'
require 'hackle-ruby-sdk/model/variation'

require 'hackle-ruby-sdk/workspace/http_workspace_fetcher'
require 'hackle-ruby-sdk/workspace/polling_workspace_fetcher'
require 'hackle-ruby-sdk/workspace/workspace'

require 'hackle-ruby-sdk/client'
require 'hackle-ruby-sdk/clients'
require 'hackle-ruby-sdk/config'
require 'hackle-ruby-sdk/version'
# client = Hackle::Client.create('Ij3eRnhYMLrv8r9jzOSr9CjmNbhuZipK')
#
# variation = client.variation(39, 'as3d153114f3')
#
# puts variation
#

config = Hackle::Config.new(base_uri: 'http://sdk.hackledev.com', event_uri: 'http://event.hackledev.com')

client = Hackle::Client.create('OjbjoArhGGb2RS58WF2eFR4LVjh2We22', config)

1.times do
  Thread.new do
    loop do
      user_id = (Time.now.to_f * 1000).to_i.to_s
      client.variation(7, user_id)
      client.track('qgafdafsdf', user_id)
      sleep(1)
    end
  end
end

sleep(100000000)