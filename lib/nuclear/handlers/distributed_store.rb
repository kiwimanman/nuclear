require 'nuclear/transaction_log'
require 'nuclear/handlers/replica_connections'

module Nuclear
  module Handlers
    class DistributedStore
      include ReplicaConnections

      attr_accessor :port, :log

      def initialize(port, num_children, log = nil)
        self.log = log || TransactionLog.new
        self.port = port
        build_replica_connections(port, num_children)
      end

      def put(key, value)
        puts "put(#{key}, #{value})"
        transaction_id = log.next_transaction(key).to_s
        unless log.transaction_aborted?(transaction_id)
          broadcast do
            client.put(key,value,transaction_id)
            client.votereq(transaction_id)
          end
        end
        transaction_id
      end

      def get(key)
        puts "get(#{key})"
        value = connect_with(replica_connections.sample) do |client|
          client.get(key)
        end
        puts value
        value
      end

      def remove(key)
        puts "remove(key)" 
      end

      def status(transaction_id)
        log.status_of(transaction_id)
      end
    end
  end
end
