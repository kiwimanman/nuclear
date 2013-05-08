require 'spec_helper'

describe Nuclear::Handlers::DistributedStore do
  context 'with one child' do
    let(:master) { Nuclear::Handlers::DistributedStore.new(4000, 1) }
   
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

  context 'with two children' do
    let(:master) { Nuclear::Handlers::DistributedStore.new(4000, 2) }
   
    context '#cast_vote' do
      let(:transaction_id) { '12345' }
      before do
        # Dont broadcast in these tests
        master.stub(:broadcast)
      end

      context 'the first vote' do
        context 'with yes' do
          it 'does not commit the transaction' do
            master.should_not_receive(:commit).with(transaction_id)
            master.cast_vote(transaction_id, Nuclear::Vote::YES)
          end

          context 'the second vote' do
            before do
              master.cast_vote(transaction_id, Nuclear::Vote::YES)
            end
            it 'with yes commits the transaction' do
              master.should_receive(:commit).with(transaction_id)
              master.cast_vote(transaction_id, Nuclear::Vote::YES)
            end
          end
        end
        context 'with no' do
          it 'aborts the transaction' do 
            master.should_receive(:abort).with(transaction_id)
            master.cast_vote(transaction_id, Nuclear::Vote::NO)
          end
          context 'the second vote' do
            before do
              master.cast_vote(transaction_id, Nuclear::Vote::NO)
            end
            context 'with yes' do
              it 'does not commit the transaction' do
                master.should_not_receive(:commit).with(transaction_id)
                master.cast_vote(transaction_id, Nuclear::Vote::YES)
              end
            end
          end
        end
      end
    end
  end
end