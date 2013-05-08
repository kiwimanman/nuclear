require 'spec_helper'

describe Nuclear::Handlers::Replica do
  let(:replica) do
    Nuclear::Handlers::Replica.new(4100)
  end
  context '#master_port' do
    it { expect(replica.master_port).to eq 4000 }
  end
end