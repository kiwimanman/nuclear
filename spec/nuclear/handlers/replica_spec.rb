require 'spec_helper'

describe Nuclear::Handlers::Replica do
  let(:log) do
    system('rm spec/logs/blank.log')
    Nuclear::TransactionLog.new("spec/logs/blank.log")
  end
  let(:replica) do
    Nuclear::Handlers::Replica.new(4100, 4100, log)
  end
  context '#master_port' do
    it { expect(replica.master_port).to eq 4000 }
  end

  context '#put' do
    let(:key) { 'test' }
    let(:value) { 'asdf' }
    before do
      replica.put(key, value, 0)
    end
    it { expect(replica.transactors[key]).to_not be_nil }

    context 'followed by #put on a different key' do
      let(:other_key) { 'bogus' }
      before do
        replica.put(other_key, value, 1)
      end
      it { expect(replica.transactors[other_key]).to_not be_nil }
    end

    context 'followed by #get on the same key' do
      it { expect(replica.get(key)).to eq value }
    end

    context 'followed by #remove on the same key' do
      before do
        replica.remove(key, 1)
      end
      it { expect(replica.status(1)).to be Nuclear::Status::ABORTED }
    end
  end
end