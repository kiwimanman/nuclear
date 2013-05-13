require 'spec_helper'

describe Nuclear::Transaction do
  context 'defaults' do
    let(:transaction) { Nuclear::Transaction.new(0) }
    it { expect(transaction.transaction_id).to be 0 }
    it { expect(transaction.votes).to be 0 }
    it { expect(transaction.last_touched).to_not be_nil }

    context '#read_log_line' do
      context 'reads remove' do
        before do
          transaction.read_log_line("start remove test")
        end
        it { expect(transaction.operation).to be :remove}
        it { expect(transaction.key).to eq 'test' }
        it { expect(transaction.args).to eq [] }
        it { expect(transaction.status).to be Nuclear::Status::PENDING }
      end

      context 'reads puts' do
        before do
          transaction.read_log_line("start put test asdf")
        end
        it { expect(transaction.operation).to be :put}
        it { expect(transaction.key).to eq 'test' }
        it { expect(transaction.args).to eq ['asdf'] }
        it { expect(transaction.status).to be Nuclear::Status::PENDING }

        context 'read commit' do
          before do
            transaction.read_log_line "commit"
          end
          it { expect(transaction.status).to be Nuclear::Status::COMMIT }
        end

        context 'read commited' do
          before do
            transaction.read_log_line "commited"
          end
          it { expect(transaction.status).to be Nuclear::Status::COMMITED }
        end
      end
    end
  end

  context 'start' do
    let(:transaction) { Nuclear::Transaction.start(0, 'put', 'test', 'asdf') }
    it { expect(transaction.transaction_id).to be 0 }
    it { expect(transaction.votes).to be 0 }
    it { expect(transaction.last_touched).to_not be_nil }
    it { expect(transaction.operation).to be :put }
    it { expect(transaction.key).to eq 'test' }
    it { expect(transaction.args).to eq ['asdf'] }
    it { expect(transaction.status).to be Nuclear::Status::PENDING }

    context '#replay' do
      it 'should replay on the replica' do
        replica = double
        replica.should_receive(:send).with(:put, 'test', 'asdf', 0)
        transaction.replay(replica)
      end
    end
  end
end