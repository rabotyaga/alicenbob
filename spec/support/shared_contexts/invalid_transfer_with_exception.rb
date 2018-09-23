# frozen_string_literal: true

shared_context 'invalid transfer with exception' do
  let(:alice) { Account.create(name: 'Alice', balance: 100) }
  let(:bob) { Account.create(name: 'Bob', balance: 100) }

  it 'raises validation error, both balances stay unchanged' do
    aggregate_failures do
      expect { described_class.call(bob, alice, 200) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect(alice.reload.balance).to eq 100
      expect(bob.reload.balance).to eq 100
    end
  end
end
