require 'thread'

module Nuclear
  class TransactionLog
    attr_accessor :mutex, :transaction_index, :key_locks
    attr_accessor :transation_records, :log
    Transaction = Struct.new(:status)

    def initialize(log_path = 'logs/master.log')
      self.log = log_path.kind_of?(String) ? File.open(log_path, 'r+') : log_path
      self.log.sync
      self.mutex = Mutex.new
      self.transaction_index = 0
      self.key_locks = Set.new
      self.transation_records = {}

      start_from_log
    end

    def next_transaction(key)
      mutex.synchronize do
        status = key_locks.include?(key) ? Status::ABORTED : Status::PENDING
        key_locks << key
        
        transaction_id = transaction_index
        self.transaction_index += 1
      end
      log.puts transaction_id
      transation_records[transaction_id] = Transaction.new(status)
      transaction_id
    end

    def transaction_status(transaction_id)
      transation_records[transaction_id].status
    end

    def transaction_pending?(transaction_id)
      transaction_status(transaction_id) == Status::PENDING
    end

    def transaction_aborted?(transaction_id)
      transaction_status(transaction_id) == Status::ABORTED
    end

    def commit_transaction(transaction_id)
      log.puts "#{transaction_id} commit"
      transation_records[transaction_id].status = Status::COMMITED
    end

    def abort_transaction(transaction_id)
      log.puts "#{transaction_id} abort"
      transation_records[transaction_id].status = Status::ABORTED
    end

    private

    def start_from_log
      log.each do |line|
        transaction_id, status = line.split(' ')
        transaction_id = transaction_id.to_i

        status = Status::ABORTED  if status =~ /abort/
        status = Status::COMMITED if status =~ /commit/

        transation_records[transaction_id] = Transaction.new(status || Status::PENDING)

        self.transaction_index = [transaction_id + 1, transaction_index].max
      end

      transation_records.each do |t_id, v|
        abort_transaction(t_id) if transaction_pending?(t_id)
      end
    end
  end
end