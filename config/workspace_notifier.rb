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
