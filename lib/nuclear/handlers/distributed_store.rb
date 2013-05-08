require 'nuclear/transaction_log'
require 'nuclear/handlers/replica_connections'

module Nuclear
  module Handlers
    class DistributedStore
      include ReplicaConnections

      attr_accessor :port, :log, :num_children

      def initialize(port, num_children, log = nil)
        self.log = log || TransactionLog.new
        self.num_children = num_children
        self.port = port
        build_replica_connections(port, num_children)
      end

      def put(key, value)
        puts "put(#{key}, #{value})"
        transaction_id = log.next_transaction(key).to_s
        unless log.aborted?(transaction_id)
          broadcast do |client|
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
        transaction_id = log.next_transaction(key).to_s
        unless log.aborted?(transaction_id)
          broadcast do |client|
            client.remove(key)
            client.votereq(transaction_id)
          end
        end
        transaction_id
      end

      def cast_vote(transaction_id, vote)
        puts "cast_vote(#{transaction_id},#{vote})"
        if vote == Vote::NO
          abort(transaction_id)
        else
          log.upvote(transaction_id)
          commit(transaction_id) if log.total_votes_on(transaction_id) == num_children
        end
      end

      def status(transaction_id)
        log.status_of(transaction_id)
      end

      private

      def abort(transaction_id)
        log.abort(transaction_id)
        broadcast do |client|
          client.finalize(transaction_id, Status::ABORTED)
        end
      end

      def commit(transaction_id)
        puts "commit(#{transaction_id})"
        log.commit(transaction_id)
        broadcast do |client|
          client.finalize(transaction_id, Status::COMMITED)
        end
      end
    end
  end
end
