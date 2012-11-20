require 'goliath'
require 'grape'

class MyAPI < Grape::API

  version 'v1', :using => :path

  resource 'workspace' do
    get "/:id" do
      pt = EM.add_periodic_timer(1) do
       env.stream_send("data:hello ##{params['id']}\n\n")
      end

      EM.add_periodic_timer(3) do
        pt.cancel

        env.stream_send("!! BOOM !!\n")
        env.stream_close
      end
    end
  end
end

class SSE < Goliath::API
  def response(env)
    MyAPI.call(env)
    [200, {}, Goliath::Response::STREAMING]
  end

end
