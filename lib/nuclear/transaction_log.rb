require 'thread'

module Nuclear
  class TransactionLog
    attr_accessor :mutex, :transaction_index, :key_locks, :vote_lock
    attr_accessor :transation_records, :log
    Transaction = Struct.new(:status, :votes)

    def initialize(log_path = 'logs/master.log')
      if log_path.kind_of?(String)

        self.log = File.open(log_path, File.exists?(log_path) ? 'r+' : 'a+')
      else
        self.log = log_path
      end

      self.log.sync
      self.mutex = Mutex.new
      self.vote_lock = Mutex.new
      self.transaction_index = 0
      self.key_locks = Set.new
      self.transation_records = {}

      start_from_log
    end

    def add_transaction(key, transaction_id)
      status = Status::PENDING

      mutex.synchronize do
        status = Status::ABORTED if key_locks.include?(key)
        key_locks << key
      end
      
      log.puts transaction_id
      transation_records[transaction_id] = Transaction.new(status, 0)
      status
    end

    def next_transaction(key)
      # Sane defaults and scoping
      transaction_id = transaction_index

      # Thread safety, re-evaluate stuff
      mutex.synchronize do
        transaction_id = transaction_index
        self.transaction_index += 1
      end

      add_transaction(key, transaction_id)
      transaction_id
    end

    def status(transaction_id)
      transation_records[transaction_id.to_i].status
    end
    alias_method :status_of, :status

    def pending?(transaction_id)
      status(transaction_id.to_i) == Status::PENDING
    end

    def aborted?(transaction_id)
      status(transaction_id.to_i) == Status::ABORTED
    end

    def uncertain?(transaction_id)
      status(transaction_id.to_i) == Status::UNCERTAIN
    end

    def commit(transaction_id)
      log.puts "#{transaction_id} commit"
      transation_records[transaction_id.to_i].status = Status::COMMITED
    end

    def abort(transaction_id)
      log.puts "#{transaction_id} abort"
      transation_records[transaction_id.to_i].status = Status::ABORTED
    end

    def upvote(transaction_id)
      log.puts "#{transaction_id} voted"
      vote_lock.synchronize do
        transation_records[transaction_id.to_i] ||= Transaction.new(Status::PENDING, 0)
        transation_records[transaction_id.to_i].votes ||= 0
        transation_records[transaction_id.to_i].votes += 1
      end
    end

    def total_votes_on(transaction_id)
      transation_records[transaction_id.to_i].votes
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