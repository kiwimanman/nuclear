require 'spec_helper'

describe Nuclear::Storage do
  let(:db_path) { 'test.db' }
  let(:store) { 
    system("rm -rf #{db_path}") # look ma, I'm rails
    Nuclear::Storage.new(db_path)
  }
  it { expect(store).to_not be_nil }

  context '#get' do
    context 'on a bad key' do
      it { expect(store.get(:asdf)).to be_nil}
    end

    context 'after a put' do
      let(:key) { :constant }
      let(:value) { 'value' }
      before do
        store.put(key, value)
      end
      it { expect(store.get(key)).to eq value }
    end
  end

  context '#put' do
    context 'on the same key' do
      it 'errors if another trys to put again' do
        store.put(:conflict, 'north')
        expect(store.get(:conflict)).to eq 'north'
        store.put(:conflict, 'south')
        expect(store.get(:conflict)).to eq 'south'
      end
    end
  end

  context '#delete' do
    before do
      store.put(:doomed, "qwerty")
      store.delete(:doomed)
    end
    it { expect(store.get(:doomed)).to be_nil }
  end

  context 'two storage handles' do
    let(:store1) do
      system("rm -rf #{db_path}") # look ma, I'm rails
      Nuclear::Storage.new(db_path, :auto_commit => false)
    end
    let(:store2) do
      Nuclear::Storage.new(db_path, :auto_commit => false)
    end
    before do
      store1.put('qwerty', '1')
    end
    it 'can not be seen by other stores till commited' do
      expect(store2.get('qwerty')).to be_nil
    end

    context 'with a new store (say after a crash)' do
      let(:store3) do
        Nuclear::Storage.new(db_path, :auto_commit => false)
      end
      it 'can not be seen by other stores till commited' do
        expect(store3.get('qwerty')).to be_nil
      end
      context 'after commit' do
        before do
          store1.commit
        end
        it { expect(store3.get('qwerty')).to eq '1' }
      end
    end

  end
end