$: << File.dirname(__FILE__)

require 'goliath'

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
    env.notifier.unsubscribe(env['workspace'], env['subscription'])
  end

  def response(env)
    env['workspace'] = params['id']

    env['subscription'] = env.notifier.subscribe env['workspace'] do |m|
      env.stream_send(m)
    end

    streaming_response(200, {'Content-Type' => 'text/event-stream'})
  end
end
