require 'thread'

module Nuclear
  class TransactionLog
    include Celluloid

    attr_accessor :transaction_index, :key_locks
    attr_accessor :transation_records, :log, :timeout

    Transaction = Struct.new(:status, :votes, :key, :last_touched)

    def initialize(log_path = 'logs/master.log')
      if log_path.kind_of?(String)

        self.log = File.open(log_path, File.exists?(log_path) ? 'r+' : 'a+')
      else
        self.log = log_path
      end

      self.log.sync
      self.transaction_index = 0
      self.key_locks = Set.new
      self.transation_records = {}
      self.timeout = 5

      start_from_log
    end

    def add_transaction(key, transaction_id)
      status = key_locks.include?(key) ? Status::ABORTED : Status::PENDING

      key_locks << key
      
      log.puts transaction_id
      transation_records[transaction_id.to_i] = Transaction.new(status, 0, key, Time.now)
      status
    end

    def next_transaction(key)
      transaction_id = transaction_index
      self.transaction_index += 1

      add_transaction(key, transaction_id)
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
      debugger if $debug
      touch(transaction_id)
      status(transaction_id.to_i) == Status::UNCERTAIN
    end

    def commit(transaction_id)
      log.puts "#{transaction_id} commit"
      transaction = transation_records[transaction_id.to_i]
      transaction.status = Status::COMMITED
      key_locks.delete(transaction.key) if transaction.key
    end

    def abort(transaction_id)
      log.puts "#{transaction_id} abort"
      transaction = transation_records[transaction_id.to_i]
      transaction.status = Status::ABORTED if transaction.status == Status::PENDING
      key_locks.delete(transaction.key) if transaction.key
    end

    def upvote(transaction_id)
      log.puts "#{transaction_id} voted"

      touch(transaction_id)
      transation_records[transaction_id.to_i] ||= Transaction.new(Status::PENDING, 0)
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

    private

    def start_from_log
      log.each do |line|
        transaction_id, status = line.split(' ')
        transaction_id = transaction_id.to_i

        status = Status::ABORTED   if status =~ /abort/
        status = Status::COMMITED  if status =~ /commit/
        status = Status::UNCERTAIN if status =~ /voted/

        transation_records[transaction_id] = Transaction.new(status || Status::PENDING)

        self.transaction_index = [transaction_id + 1, transaction_index].max
      end

      transation_records.each do |t_id, v|
        abort(t_id) if pending?(t_id) && !uncertain?(t_id)
      end
    end
  end
end