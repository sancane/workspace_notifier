require 'goliath'
require 'em-synchrony/activerecord'

class VirtualMachine < ActiveRecord::Base
end

class WorkspaceNotifier < Goliath::API
  include Goliath::Rack::Types

  use Goliath::Rack::Params
  use Goliath::Rack::Tracer
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'id'}
  use Goliath::Rack::Validation::Param, :key => 'id', :as => Integer,
                                  :message => "Id needs to be an Integer"

  use Rack::Static, :urls => ["/index.html"],
                      :root => Goliath::Application.app_path("public")

  def on_close(env)
    env.channels[env['workspace']].unsubscribe(env['subscription'])
  end

  def send_message(id, channel)
    EventMachine.synchrony do
      obj = {
        "workspace" => id,
        "nodes" => []
      }

      VirtualMachine.find_all_by_workspace_id(id).each do |vm|
        obj['nodes'].push({
          "name" => vm.name,
          "state" => vm.state
        })
      end

      msg = ["event:workspace", "data:#{obj.to_json}\n\n"].join("\n")
      channel << msg
    end
  end

  def response(env)
    env['workspace'] = params['id']

    if not env.channels[env['workspace']]
      env.channels[env['workspace']] = EventMachine::Channel.new
      env.timers[env['workspace']] = EM.add_periodic_timer(2) do
        send_message(env['workspace'], env.channels[env['workspace']])
      end
    end

    env['subscription'] = env.channels[env['workspace']].subscribe do |m|
      env.stream_send(m)
    end

    streaming_response(200, {'Content-Type' => 'text/event-stream'})
  end
end
