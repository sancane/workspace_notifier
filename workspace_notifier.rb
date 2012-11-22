require 'goliath'
require 'em-synchrony/activerecord'

class User < ActiveRecord::Base
end

class WorkspaceNotifier < Goliath::API
  include Goliath::Rack::Types

  use Goliath::Rack::Params
  use Goliath::Rack::Tracer
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'workspace'}
  use Goliath::Rack::Validation::Param, :key => 'workspace', :as => Integer,
                                  :message => "Workspace needs to be an Integer"

  use Rack::Static, :urls => ["/index.html"],
                      :root => Goliath::Application.app_path("public")

  def on_close(env)
    env.logger.info "TODO: Close connection."
  end

  def response(env)
    User.all.each do |user|
      env.logger.info("-------------------#{user.first_name}")
    end

    env.logger.info("----->: #{env.params}")

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
