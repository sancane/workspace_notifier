require 'app/models/virtual_machine'

class Notifier
  public
  def initialize(workspace_id)
    @id = workspace_id
    @nodes = {}
    @subs = []
    @channel = EventMachine::Channel.new
  end

  def subscribe(*a, &b)
    name = @channel.subscribe(*a, &b)
    if @subs.count == 0
      @timer = EM.add_periodic_timer(2) { check_workspace }
    end
    @subs.push(name)
    return name
  end

  def unsubscribe(name)
    @channel.unsubscribe(name)
    @subs.delete(name)
    if @subs.count == 0
      @timer.cancel
    end
  end

  private
  def update_nodes(node_dict)
    changes = {}
    node_dict.keys.each do |node|
      if not @nodes[node] or @nodes[node] != node_dict[node]
        @nodes[node] = node_dict[node]
        changes[node] = node_dict[node]
      end
    end

    return changes
  end

  def create_json
    obj = {
      "workspace" => @id,
      "nodes" => []
    }

    @nodes.keys.each do |node|
      obj['nodes'].push({
        "name" => node,
        "state" => @nodes[node]
      })
    end

    obj.to_json
  end

  def check_workspace
    EventMachine.synchrony do
      nodes = {}
      VirtualMachine.find_all_by_workspace_id(@id).each do |vm|
        nodes[vm.name] = vm.state
      end

      update_nodes(nodes)
      msg = ["event:workspace", "data:#{create_json}\n\n"].join("\n")
      @channel << msg
    end
  end
end
