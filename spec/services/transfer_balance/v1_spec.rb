# frozen_string_literal: true

describe TransferBalance::V1 do
  let(:alice) { Account.create(name: 'Alice', balance: 100) }
  let(:bob) { Account.create(name: 'Bob', balance: 100) }

  context 'with valid transfer' do
    before do
      described_class.call(bob, alice, 100)
    end

    it 'Bob`s balance = 0, Alice`s balance = 200' do
      expect(bob.reload.balance).to be_zero
      expect(alice.reload.balance).to eq 200
    end
  end

  context 'with invalid transfer' do
    before do
      described_class.call(bob, alice, 200)
    end

    it 'both balances stay unchanged' do
      expect(bob.reload.balance).to eq 100
      expect(alice.reload.balance).to eq 100
    end
  end
end
