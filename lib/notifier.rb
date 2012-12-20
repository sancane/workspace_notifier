require 'amqp'
require 'json'

class Notifier
  public
  def initialize(workspace_id)
    @id = workspace_id
    @nodes = {}
    @subs = []
    @channel = EventMachine::Channel.new
    get_workspace
  end

  def subscribe(*a, &b)
    name = @channel.subscribe(*a, &b)
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
  end

  def send(event)
    send_notification(event["nodes"])
  end

  private
  def listen_to_events
    @amqp_chan = AMQP::Channel.new
    name = "netlab.events.#{Goliath::env}.workspace.#{@id}"
    @exchange = @amqp_chan.direct(name)
    @queue = @amqp_chan.queue("", :exclusive => true, :auto_delete => true).bind(@exchange)

    @queue.subscribe do |headers, payload|
      begin
        event = JSON.parse(payload)
        send_notification(event["nodes"])
      rescue Exception
        # Ignore it
      end
    end
  end

  def get_workspace
    tmp_chann = AMQP::Channel.new
    reply_queue = tmp_chann.queue("", :exclusive => true, :auto_delete => true) do |queue|
      tmp_chann.default_exchange.publish(@id.to_s,
        :routing_key => "netlab.services.#{Goliath::env}.workspace.state",
        :message_id => Kernel.rand(10101010).to_s,
        :persistent => true,
        :reply_to => queue.name)
    end

    reply_queue.subscribe do |metadata, payload|
      begin
        puts "[response] Response for #{payload}"
        reply = JSON.parse(payload)
        raise if reply["workspace"] != @id
        send_notification(reply["nodes"])
        listen_to_events
      rescue Exception => e
        puts e.message
        puts e.backtrace
        #TODO: Send error notification to all clients
      ensure
        tmp_chann.close
      end
    end
  end

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

  def notify(node_dict)
    updated = update_nodes(node_dict)
    if updated.keys.length > 0
      # Send updated nodes to all clients
      @channel << create_event(updated)
    end
  end

  def send_notification(nodes)
    nodes_dict = {}
    nodes.each do |vm|
      nodes_dict[vm["name"]] = vm["state"]
    end

    notify(nodes_dict)
  end
end
