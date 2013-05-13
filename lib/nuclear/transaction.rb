module Nuclear
  class Transaction
    attr_accessor :status, :votes, :key, :last_touched, :operation, :args, :transaction_id

    def self.start(transaction_id, operation, key, *args)
      t = Transaction.new(transaction_id)
      t.operation = operation.to_sym
      t.key = key
      t.args = args
      t.status = Status::PENDING
      t
    end

    def initialize(transaction_id)
      self.transaction_id = transaction_id
      self.last_touched = Time.now
      self.votes = 0
    end

    def read_log_line(line)
      args = line.split(' ')
      status = args[0]

      if status =~ /start/
        self.status = Status::PENDING
        self.operation = args[1].to_sym
        self.key = args[2]
        self.args = args[3..-1]
      end

      self.status = Status::ABORTED   if status =~ /abort/
      self.status = Status::COMMIT    if status =~ /commit/
      self.status = Status::COMMITED  if status =~ /commited/
      self.status = Status::UNCERTAIN if status =~ /voted/
    end

    def replay(replica)
      replica.send(*([operation, key] + args << transaction_id))
    end
  end
end