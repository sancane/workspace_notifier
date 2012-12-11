require 'lib/notifier'

class NotifyHandler
  def initialize
    @watchers = {}
  end

  def subscribe(workspace_id, *a, &b)
    if not @watchers[workspace_id]
      @watchers[workspace_id] = Notifier.new(workspace_id)
    end

    @watchers[workspace_id].subscribe(*a, &b)
  end

  def unsubscribe(workspace_id, name)
    return if not @watchers[workspace_id]
    @watchers[workspace_id].unsubscribe(name)
  end

  def notify(event)
    workspace_id = event["workspace"]
    return if not @watchers[workspace_id]
    @watchers[workspace_id].send(event)
  end
end
