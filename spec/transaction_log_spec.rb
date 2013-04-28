require 'spec_helper'

describe Nuclear::TransactionLog do
  context 'master transaction log' do
    context 'with no open transactions' do
      let(:t_log) do
        Nuclear::TransactionLog.new('spec/logs/master.log')
      end
      it 'sets the next transaction to be larger than the last known transaction' do
        expect(t_log.transaction_index > 3).to be_true
      end
    end

    context 'with open transactions' do
      let(:file) do
        f = File.open('spec/logs/master.log', 'r+')
        f.instance_eval do
          def each
            ['1',
             '2',
             '2 abort',
             '3',
             '3 commit'].each do |line|
              yield line
            end
          end
        end
        f
      end
      let(:t_log) do
        Nuclear::TransactionLog.new(file)
      end
      it 'aborts the open transaction' do
        file.should_receive(:puts).with('1 abort')
        t_log
      end
    end
  end
end