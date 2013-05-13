require 'nuclear/transaction_log'
require 'nuclear/handlers/replica_connections'
require 'nuclear/handlers/timeout_checker'

module Nuclear
  module Handlers
    class DistributedStore
      include ReplicaConnections
      include TimeoutChecker

      attr_accessor :port, :log, :num_children, :timeout

      def initialize(port, num_children, log = nil)
        self.log = log || TransactionLog.new
        self.num_children = num_children
        self.port = port
        self.timeout = 5
        build_replica_connections(port, num_children)
      end

      def put(key, value, transaction_id = nil)
        puts "put(#{key}, #{value})"
        transaction_id = log.next_transaction(key, :put, value).to_s
        unless log.aborted?(transaction_id)
          begin
            Timeout::timeout(timeout) {
              broadcast do |client|
                client.put(key,value,transaction_id)
                client.votereq(transaction_id)
              end
            }
          rescue
            abort(transaction_id)
          end
        end
        transaction_id
      end

      def get(key)
        puts "get(#{key})"
        value = connect_with(replica_connections.sample) do |client|
          Timeout::timeout(timeout) {
            client.get(key)
          }
        end
        puts value
        value
      end

      def remove(key, transaction_id = nil)
        puts "remove(key)"
        transaction_id = log.next_transaction(key, :remove).to_s
        unless log.aborted?(transaction_id)
          broadcast do |client|
            client.remove(key)
            client.votereq(transaction_id)
          end
        end
        transaction_id
      end

      def cast_vote(transaction_id, vote)
        puts "cast_vote(#{transaction_id},#{vote == 1 ? 'YES' : 'NO'})"
        if vote == Vote::NO
          abort(transaction_id)
        else
          log.upvote(transaction_id)
          commit(transaction_id) if log.total_votes_on(transaction_id) == num_children
        end
      end

      def status(transaction_id)
        puts "status(#{transaction_id})"
        log.status_of(transaction_id)
      end

      private

      def abort(transaction_id)
        log.abort(transaction_id)
      end

      def commit(transaction_id)
        puts "commit(#{transaction_id})"
        log.commit(transaction_id)
        begin
          broadcast do |client|
            client.finalize(transaction_id.to_s, Status::COMMITED)
          end
        rescue
        end
      end
    end
  end
end
