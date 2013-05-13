module Nuclear
  module Handlers
    module TimeoutChecker
      def check_timeouts
        pending_list = log.unfinished_transactions
        pending_list.each do |t|
          if t.last_touched - Time.now > timeout && t.status == Status::PENDING
            abort(t.transaction_id)
          end
        end
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