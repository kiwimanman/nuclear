module Nuclear
  module Handlers
    class Replica
      attr_accessor :store, :master, :port, :log

      def initialize(replica_id, port = nil, log = nil)
        replica_id = replica_id.to_s
        self.log = log || TransactionLog.new("logs/#{replica_id}.log")
        self.store = Nuclear::Storage.new("dbs/#{replica_id}.db")
        self.port  = replica_id || port
      end

      def put(key, value, transaction_id)
        puts "put(#{key}, #{value}, #{transaction_id})"
        unless log.add_transaction(key, transaction_id)
          store.put(key,value)
        end
      end

      def get(key)
        store.get(key)
      end
  
      def remove(key, transaction_id)
        puts "remove(key, transaction_id)"
      end
  
      def votereq(transaction_id)
        puts "votereq(#{transaction_id})"
        case log.status(transaction_id)
          when Status::PENDING
            upvote(transaction_id)
          when Status::UNCERTAIN
            upvote(transaction_id) # Ths should likely never happen
          else
            abort(transaction_id)
        end
      end
  
      def finalize(transaction_id, decision)
        case decision
          when Status::COMMITED
            log.commit(transaction_id)
          when Status::ABORTTED
            log.abort(transaction_id)
        end
      end

      def status(transaction_id)
        log.status(transaction_id)
      end

      def master
        return @master if @master
        transport = Thrift::BufferedTransport.new(Thrift::Socket.new('127.0.0.1', master_port))
        protocol = Thrift::BinaryProtocol.new(transport)
        @master = Nuclear::Store::Client.new(protocol)

        RemoteReplica.new(transport, @master)

        transport.open()

        @master
      end

      def master_port
        port.to_i / 100 * 100 - 100
      end

      def upvote(transaction_id)
        # write to log so we become uncertain
        # TODO
        # send vote to master
        master.cast_vote(transaction_id, Vote::YES)
      end
    end
  end
end
