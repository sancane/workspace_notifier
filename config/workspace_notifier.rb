require 'mysql2'
require 'amqp'
require 'lib/notify_handler'

config['notifier'] = NotifyHandler.new

# Database configuration
ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                        :database => 'your database',
                                        :username => 'user',
                                        :password => 'password',
                                        :host     => 'host',
                                        :pool     => 5)

# AMQP configuration
amqp_config = {
  :host => 'localhost',
  :user => 'test',
  :pass => 'test',
  :vhost => '/test'
}

connection = AMQP.connect(amqp_config)
channel = AMQP::Channel.new(connection)
queue = channel.queue("netlab.events.workspace", :auto_delete => true)
exchange = channel.direct("")

queue.subscribe do |msg|
  config['notifier'].notify(msg)
end
