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
    env.logger.info "TODO: Close connection."
  end

  def send_notification(id, env)
    EventMachine.synchrony do
      obj = {"workspace" => id}
      obj["nodes"] = []

      VirtualMachine.find_all_by_workspace_id(id).each do |vm|
        obj["nodes"].push({
          "name" => vm.name,
          "state" => vm.state
        })
      end

      env.stream_send(["event:worspace", "data:#{obj.to_json}\n\n"].join("\n"))
    end
  end

  def response(env)
    id = params['id']

    pt = EM.add_periodic_timer(2) { send_notification(id, env) }

    EM.add_periodic_timer(8) do
      pt.cancel
      env.stream_send(["event:signup", "data:signup event ##{rand(100)}\n\n"].join("\n"))
      env.stream_close
    end
    streaming_response(200, {'Content-Type' => 'text/event-stream'})
  end
end
