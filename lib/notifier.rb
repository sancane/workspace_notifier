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

    if @nodes.keys.length > 0
      EM.next_tick do
        # Send the whole workspace state to the new client
        cb = EM::Callback(*a, &b)
        cb.call(create_event(@nodes))
      end
    end

    return name
  end

  def unsubscribe(name)
    @channel.unsubscribe(name)
    @subs.delete(name)
    if @subs.count == 0
      @timer.cancel
    end
  end

  def send(event)
    puts "Received event from RabbitMQ channel #{event}"
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

  def create_json(node_dict)
    obj = {
      "workspace" => @id,
      "nodes" => []
    }

    node_dict.keys.each do |node|
      obj['nodes'].push({
        "name" => node,
        "state" => @nodes[node]
      })
    end

    obj.to_json
  end

  def create_event(nodes)
    ["event:workspace", "data:#{create_json(nodes)}\n\n"].join("\n")
  end

  def check_workspace
    EventMachine.synchrony do
      nodes = {}
      VirtualMachine.find_all_by_workspace_id(@id).each do |vm|
        nodes[vm.name] = vm.state
      end

      updated = update_nodes(nodes)
      if updated.keys.length > 0
        # Send updated nodes to all clients
        @channel << create_event(updated)
      end
    end
  end
end
