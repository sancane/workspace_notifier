require 'mysql2'

# Hash with the workspace id and the channel
config['channels'] = {}

# Hash with the workspace id and the timer
config['timers'] = {}

ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                        :database => 'your database',
                                        :username => 'user',
                                        :password => 'password',
                                        :host     => 'host',
                                        :pool     => 5)
