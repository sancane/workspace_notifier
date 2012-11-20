require 'goliath'

class SSE < Goliath::API
  use Rack::Static, :urls => ["/index.html"], :root => Goliath::Application.app_path("public")

  def response(env)
    EM.add_periodic_timer(1) do
      env.stream_send("data:hello ##{rand(100)}\n\n")
    end

    EM.add_periodic_timer(3) do
      env.stream_send(["event:signup", "data:signup event ##{rand(100)}\n\n"].join("\n"))
    end

    streaming_response(200, {'Content-Type' => 'text/event-stream'})
  end
end
