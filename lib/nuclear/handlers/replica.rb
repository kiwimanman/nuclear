require 'thread'

module Nuclear
  module Handlers
    class Replica
      attr_accessor :store, :master, :port, :log, :transactors, :db_path
      attr_accessor :mutex, :queue

      def initialize(replica_id, port = nil, log = nil)
        replica_id = replica_id.to_s
        self.db_path = "dbs/#{replica_id}.db"
        self.log = log || TransactionLog.new("logs/#{replica_id}.log")
        self.store = Nuclear::Storage.new(db_path)
        self.port  = replica_id || port
        self.transactors = {}
        self.mutex = Mutex.new
        self.queue = Queue.new

        recover
      end

      def put(key, value, transaction_id)
        puts "put(#{key}, #{value}, #{transaction_id})"
        log.add_transaction(key, transaction_id, :put, value)

        if key_conflict?(key)
          transactors[key].put(key,value)
        else
          abort(transaction_id, false)
        end
      end

      def get(key)
        store.get(key)
      end
  
      def remove(key, transaction_id)
        log.add_transaction(key, transaction_id, :remove)

        if key_conflict?(key)
          transactors[key].delete(key)
        else
          abort(transaction_id, false)
        end
      end
  
      def votereq(transaction_id)
        puts "votereq(#{transaction_id})"
        case log.status(transaction_id)
          when Status::PENDING
            upvote(transaction_id)
          when Status::UNCERTAIN
            upvote(transaction_id) # Ths should likely never happen but is safe
          else
            abort(transaction_id)
            master.cast_vote(transaction_id, Vote::NO)
        end
      end
  
      def finalize(transaction_id, decision)
        case decision
          when Status::COMMITED
            commit(transaction_id)
          when Status::ABORTTED
            abort(transaction_id)
        end
      end

      def key_conflict?(key)
        free = false
        mutex.synchronize {
          free = true if transactors[key].nil?
          transactors[key] ||= next_store
        }
        free
      end

      def next_store
        if queue.empty?
          Nuclear::Storage.new(db_path)
          store.replica = self
          store
        else
          queue.pop
        end
      end

      def enqueue(store)
        mutex.synchronize do
          queue << store
        end
      end

      def status(transaction_id)
        status = log.status(transaction_id)
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
        # 5104 becomes 5000
        port.to_i / 100 * 100 - 100
      end

      def upvote(transaction_id)
        log.upvote(transaction_id)
        master.cast_vote(transaction_id, Vote::YES)
      end

      def abort(transaction_id, clear_key_lock = true)
        log.abort(transaction_id)
        t = log.get(transaction_id)
        if clear_key_lock
          transactors[t.key].rollback 
          transactors.delete(t.key)
        end
      end

      def commit(transaction_id, clear_key_lock = true)
        log.commit(transaction_id)
        t = log.get(transaction_id)
        transactors[t.key].commit
        log.commited(transaction_id)
        transactors.delete(t.key) if clear_key_lock
      end

      def recover
        replay_list = log.unfinished_transactions
        replay_list.each do |t|
          t.replay(self)

          case t.status
          when Status::COMMIT
            commit(t.transaction_id)
          when Status::PENDING
            abort(t.transaction_id)
          end
        end
      end
    end
  end
end
