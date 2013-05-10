require 'celluloid'
require 'nuclear/transaction'

module Nuclear
  class TransactionLog
    include Celluloid

    attr_accessor :transaction_index
    attr_accessor :transation_records, :log, :timeout

    def initialize(log_path = 'logs/master.log')
      if log_path.kind_of?(String)

        Actor.current.log = File.open(log_path, File.exists?(log_path) ? 'r+' : 'a+')
      else
        Actor.current.log = log_path
      end

      Actor.current.log.sync
      Actor.current.transaction_index = 0
      Actor.current.transation_records = {}
      Actor.current.timeout = 5

      start_from_log
    end

    def add_transaction(key, transaction_id, operation, *args)  
      log.puts "#{transaction_id} start #{operation} #{key} #{args.join(' ')}"
      transation_records[transaction_id.to_i] = Transaction.start(transaction_id, operation, key, args)
      transation_records[transaction_id.to_i].status
    end

    def next_transaction(key, operation, *args)
      transaction_id = transaction_index
      Actor.current.transaction_index += 1

      add_transaction(key, transaction_id, operation, args)
      transaction_id
    end

    def status(transaction_id)
      touch(transaction_id)
      t = transation_records[transaction_id.to_i]
      t ? t.status : Status::UNCERTAIN
    end
    alias_method :status_of, :status

    def pending?(transaction_id)
      touch(transaction_id)
      status(transaction_id.to_i) == Status::PENDING
    end

    def aborted?(transaction_id)
      touch(transaction_id)
      status(transaction_id.to_i) == Status::ABORTED
    end

    def uncertain?(transaction_id)
      touch(transaction_id)
      status(transaction_id.to_i) == Status::UNCERTAIN
    end

    def commit(transaction_id)
      log.puts "#{transaction_id} commit"
      transaction = transation_records[transaction_id.to_i]
      transaction.status = Status::COMMIT
    end

    def commited(transaction_id)
      log.puts "#{transaction_id} commited"
      transaction = transation_records[transaction_id.to_i]
      transaction.status = Status::COMMITED
    end

    def abort(transaction_id)
      log.puts "#{transaction_id} abort"
      transaction = transation_records[transaction_id.to_i]
      transaction.status = Status::ABORTED if transaction.status == Status::PENDING
    end

    def upvote(transaction_id)
      log.puts "#{transaction_id} voted"

      touch(transaction_id)
      transation_records[transaction_id.to_i]
      transation_records[transaction_id.to_i].votes ||= 0
      transation_records[transaction_id.to_i].votes += 1
    end

    def total_votes_on(transaction_id)
      transation_records[transaction_id.to_i].votes
    end

    def touch(transaction_id)
      now = Time.now
      transaction = transation_records[transaction_id.to_i]
      if transaction && transaction.last_touched
        abort(transaction_id) if (now - transaction.last_touched) > timeout
      end
      transaction.last_touched = now if transaction
    end

    def get(transaction_id)
      transation_records[transaction_id.to_i]
    end

    def unfinished_transactions
      transation_records.values.select { |t| t.status == Status::PENDING || t.status == Status::COMMIT }
    end

    private

    def start_from_log
      log.each do |line|
        next if line.empty?
        transaction_id, line = line.split(' ', 2)
        transaction_id = transaction_id.to_i
  
        transation_records[transaction_id] ||= Transaction.new(transaction_id)
        transation_records[transaction_id].read_log_line(line)    

        Actor.current.transaction_index = [transaction_id + 1, transaction_index].max
      end
    end
  end
end