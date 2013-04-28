module Nuclear
  module Handlers
    class Replica
      attr_accessor :store

      def initialize(replica_id)
        replica_id = replica_id.to_s
        self.store = Nuclear::Storage.new("dbs/#{replica_id}.db")
      end

      def put(key, value, transaction_id)
        puts "put(#{key}, #{value}, #{transaction_id})"
        store.put(key,value)
      end

      def get(key)
        store.get(key)
      end
  
      def remove(key, transaction_id)
        puts "remove(key, transaction_id)"
      end
  
      def votereq(transaction_id)
        puts "votereq(#{transaction_id})"
      end
  
      def finalize(transaction_id, decision)
        puts "finalize(transaction_id, decision)"
      end

      def status(transaction_id)
        puts "status(transaction_id)"
      end
    end
  end
end
