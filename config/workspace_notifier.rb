require 'mysql2'
require 'lib/notify_handler'

config['notifier'] = NotifyHandler.new

ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                        :database => 'your database',
                                        :username => 'user',
                                        :password => 'password',
                                        :host     => 'host',
                                        :pool     => 5)
