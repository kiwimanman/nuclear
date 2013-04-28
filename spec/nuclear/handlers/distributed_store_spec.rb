require 'spec_helper'

describe Nuclear::Handlers::DistributedStore do
  let(:d_s) { Nuclear::Handlers::DistributedStore.new(4000, 1) }

  context '#status' do
    it { expect(d_s.status(1)).to be Nuclear::Status::ABORTED }
  end
end