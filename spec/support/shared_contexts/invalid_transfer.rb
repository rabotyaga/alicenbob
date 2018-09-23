# frozen_string_literal: true

shared_context 'invalid transfer' do |account_class = Account|
  let(:alice) { account_class.create(name: 'Alice', balance: 100) }
  let(:bob) { account_class.create(name: 'Bob', balance: 100) }

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
