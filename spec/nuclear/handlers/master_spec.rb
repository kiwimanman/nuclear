require 'spec_helper'

describe Nuclear::Handlers::Master do
  context 'with one child' do
    let(:master) { Nuclear::Handlers::Master.new(4000, 1) }

    context '#status' do
      it { expect(master.status(1)).to be Nuclear::Status::ABORTED }
    end
   
    context '#cast_vote' do
      let(:transaction_id) { '12345' }
      context 'with yes' do
        it 'commits the transaction' do
          master.should_receive(:commit).with(transaction_id)
          master.cast_vote(transaction_id, Nuclear::Vote::YES)
        end
      end
      context 'with no' do
        it 'aborts the transaction' do 
          master.should_receive(:abort).with(transaction_id)
          master.cast_vote(transaction_id, Nuclear::Vote::NO)
        end
      end
    end
  end
end