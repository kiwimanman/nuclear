require 'nuclear/transaction_log'

module Nuclear
  module Handlers
    RemoteReplica = Struct.new(:transport, :client)
    
    class DistributedStore
      attr_accessor :port, :replica_connections, :log

      def initialize(port, num_children)
        self.log = TransactionLog.new
        self.port = port
        self.replica_connections = (0..(num_children - 1)).map do |port_offset|
          transport = Thrift::BufferedTransport.new(Thrift::Socket.new('127.0.0.1', port + port_offset + 100))
          protocol = Thrift::BinaryProtocol.new(transport)
          client = Nuclear::Replica::Client.new(protocol)

          RemoteReplica.new(transport, client)
        end
      end

      def put(key, value)
        puts "put(#{key}, #{value})"
        transaction_id = log.next_transaction(key)
        unless transaction_aborted?(transaction_id)
          replica_connections.each do |connection|
            connect_with(connection) do |client|
              client.put(key,value,transaction_id)
            end
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
        puts "status(transaction_id)"
        transaction_status(transaction_id)
      end

      private

      def connect_with(replica)
        replica.transport.open
        value = yield replica.client
        replica_connections[0].transport.close
        value
      end
    end
  end
end
