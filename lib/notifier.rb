require 'em-synchrony/activerecord'

class VirtualMachine < ActiveRecord::Base
end

class Notifier
  public
  def initialize(workspace_id)
    @id = workspace_id
    @channel = EventMachine::Channel.new
    @timer = EM.add_periodic_timer(2) { check_workspace }
  end

  def subscribe(*a, &b)
    @channel.subscribe(*a, &b)
  end

  def unsubscribe(name)
    @channel.unsubscribe(name)
  end

  private
  def check_workspace
    EventMachine.synchrony do
      obj = {
        "workspace" => @id,
        "nodes" => []
      }

      VirtualMachine.find_all_by_workspace_id(@id).each do |vm|
        obj['nodes'].push({
          "name" => vm.name,
          "state" => vm.state
        })
      end

      msg = ["event:workspace", "data:#{obj.to_json}\n\n"].join("\n")
      @channel << msg
    end
  end
end
