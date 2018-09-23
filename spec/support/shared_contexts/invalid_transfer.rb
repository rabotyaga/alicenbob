# frozen_string_literal: true

shared_context 'invalid transfer' do
  let(:alice) { Account.create(name: 'Alice', balance: 100) }
  let(:bob) { Account.create(name: 'Bob', balance: 100) }

  before do
    described_class.call(bob, alice, 200)
  end

  it 'both balances stay unchanged' do
    aggregate_failures do
      expect(bob.reload.balance).to eq 100
      expect(alice.reload.balance).to eq 100
    end
  end
end
