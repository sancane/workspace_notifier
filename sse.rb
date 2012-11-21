require 'goliath'

class Workspace < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'workspace'}
  use Goliath::Rack::Validation::Param, :key => 'workspace',
                                  :as => Goliath::Rack::Types::Integer,
                                  :message => "Workspace needs to be an Integer"

  use Rack::Static, :urls => ["/index.html"],
                      :root => Goliath::Application.app_path("public")

  def response(env)
    pt = EM.add_periodic_timer(1) do
      env.stream_send("data:hello ##{rand(100)}\n\n")
    end

    EM.add_periodic_timer(5) do
      pt.cancel
      env.stream_send(["event:signup", "data:signup event ##{rand(100)}\n\n"].join("\n"))
      env.stream_close
    end
    streaming_response(200, {'Content-Type' => 'text/event-stream'})
  end
end
