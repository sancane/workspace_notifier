class Notifier
  public
  def initialize(workspace_id)
    @id = workspace_id
    @channel = EventMachine::Channel.new
    @timer = EM.add_periodic_timer(2) { check_workspace }
  end

  def subscribe(*a, &b)
    puts "--> TODO: Implement subscribe"
  end

  def unsubscribe(name)
    puts "--> TODO: Implement unsubscribe"
  end

  private
  def check_workspace
    puts "TODO: Pull data base"
  end
end
