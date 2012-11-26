require 'app/models/virtual_machine'

class Notifier
  public
  def initialize(workspace_id)
    @id = workspace_id
    @channel = EventMachine::Channel.new
    @subs = {}
  end

  def subscribe(*a, &b)
    name = @channel.subscribe(*a, &b)
    if @subs.keys.length == 0
      @timer = EM.add_periodic_timer(2) { check_workspace }
    end
    @subs[name] = false
    return name
  end

  def unsubscribe(name)
    @channel.unsubscribe(name)
    @subs.delete(name)
    if @subs.keys.length == 0
      puts "Removing timer"
      @timer.cancel
    end
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
