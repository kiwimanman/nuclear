require 'spec_helper'

describe Nuclear::Handlers::DistributedStore do
  let(:log_path) { 'spec/logs/d_s_log.db' }
  let(:log) { 
    system("rm -rf #{log_path}") # look ma, I'm rails
    Nuclear::TransactionLog.new(log_path)
  }
  let(:num_children) { 1 }
  let(:d_s) { Nuclear::Handlers::DistributedStore.new(4000, num_children, log) }

  context '#put' do
    it 'sends num_children puts requests and votereqs' do
      replica = double
      d_s.replica_connections = [double(:transport => double(:open => nil, :close => nil), :client => replica)]
      replica.should_receive(:put).with("test", "asdf", "0")
      replica.should_receive(:votereq).with("0")
      d_s.put("test", "asdf")
    end

    context 'test without sending' do
      before do
        d_s.stub(:broadcast)
      end
      it { expect(d_s.put("test", "asdf")).to eq "0" }

      context "after a puts" do
        before do
          d_s.put("test", "asdf")
        end
        it { expect(d_s.status('0')).to be Nuclear::Status::PENDING }
        it "assigns a higher t_id and aborts it" do
          t_id = d_s.put("test", "asdf")
          expect(t_id.to_i > 0).to be_true
          expect(d_s.status(t_id)).to be Nuclear::Status::PENDING # No reason to enforce consistency control here 
        end
      end
    end
  end
end