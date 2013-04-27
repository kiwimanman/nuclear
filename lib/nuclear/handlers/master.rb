module Nuclear
  module Handlers
    class Master
      def cast_vote(transaction_id, vote)
        puts "cast_vote"
      end

      def status(transaction_id)
        puts "status"
      end
    end
  end
end
