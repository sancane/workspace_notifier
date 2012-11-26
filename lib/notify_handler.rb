require 'lib/notifier'

class NotifyHandler
  def initialize
    @subs = {}
  end

  def subscribe(workspace_id, *a, &b)
    puts "TODO: Implement subscribe for #{workspace_id}"
  end

  def unsubscribe(workspace_id, name)
    puts "TODO: Implement unsubscribe"
  end
end
