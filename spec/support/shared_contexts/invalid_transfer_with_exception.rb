# frozen_string_literal: true

shared_context 'invalid transfer with exception' do |account_class = Account|
  let(:alice) { account_class.create(name: 'Alice', balance: 100) }
  let(:bob) { account_class.create(name: 'Bob', balance: 100) }

  it 'raises validation error, both balances stay unchanged' do
    aggregate_failures do
      expect { described_class.call(bob, alice, 200) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect(alice.reload.balance).to eq 100
      expect(bob.reload.balance).to eq 100
    end
  end
end
