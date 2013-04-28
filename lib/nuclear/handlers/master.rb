require 'nuclear/transaction_log'
require 'nuclear/handlers/replica_connections'

module Nuclear
  module Handlers
    class Master
      include ReplicaConnections

      attr_accessor :log, :num_children

      def initialize(port, num_children, log = nil)
        self.log = log || TransactionLog.new
        self.num_children = num_children
        build_replica_connections(port, num_children)
      end

      def cast_vote(transaction_id, vote)
        if vote == Nuclear::Vote::NO
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
        broadcast do
          transaction_id
        end
      end

      def commit(transaction_id)
        log.commit(transaction_id)
        broadcast do
          transaction_id
        end
      end
    end
  end
end
