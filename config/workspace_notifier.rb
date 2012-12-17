require 'amqp'
require 'lib/notify_handler'

config['notifier'] = NotifyHandler.new

# AMQP configuration
amqp_config = {
  :host => 'localhost',
  :user => 'test',
  :pass => 'test',
  :vhost => '/test',
  :ssl       => true,
  :heartbeat => 1
}

connection = AMQP.connect(amqp_config)
channel = AMQP::Channel.new(connection)

exchange = channel.fanout("netlab.events.workspace")
queue = channel.queue("", :exclusive => true, :auto_delete => true).bind(exchange)

queue.subscribe do |headers, payload|
  begin
    event = JSON.parse(payload)
    config['notifier'].notify(event)
  rescue Exception => e
    logger.error(e.message)
    logger.error(e.backtrace)
  end
end
