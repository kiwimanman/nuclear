module Nuclear
  module Handlers
    RemoteReplica = Struct.new(:transport, :client)

    module ReplicaConnections
      attr_accessor :replica_connections

      def build_replica_connections(port, num_children)
        self.replica_connections = (0..(num_children - 1)).map do |port_offset|
          transport = Thrift::BufferedTransport.new(Thrift::Socket.new('127.0.0.1', port + port_offset + 100))
          protocol = Thrift::BinaryProtocol.new(transport)
          client = Nuclear::Replica::Client.new(protocol)

          RemoteReplica.new(transport, client)
        end
      end

      def broadcast
        replica_connections.each do |connection|
          connect_with(connection) do |client|
            yield client
          end
        end
      end

      def connect_with(replica)
        replica.transport.open
        value = yield replica.client
        replica_connections[0].transport.close
        value
      end
    end
  end
end