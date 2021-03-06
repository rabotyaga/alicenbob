# frozen_string_literal: true

shared_context 'handles deadlocks' do |account_class = Account|
  let(:alice) { account_class.create(name: 'Alice', balance: 1100) }
  let(:bob) { account_class.create(name: 'Bob', balance: 1100) }

  before do
    alice # create Alice
    bob # create Bob
  end

  it 'handles deadlocks' do
    aggregate_failures do
      expect(ActiveRecord::Base.connection.pool.size).to be > 4
      available_db_connections = 4

      fails = Array.new(available_db_connections) { false }

      threads = Array.new(available_db_connections) do |i|
        Thread.new do
          alice = account_class.find_by!(name: 'Alice')
          bob = account_class.find_by!(name: 'Bob')
          begin
            if i.even?
              described_class.call(bob, alice, 100)
            else
              described_class.call(alice, bob, 100)
            end
          rescue ActiveRecord::RecordInvalid
            fails[i] = true
          end
        end
      end

      threads.each(&:join)
      expect(fails.count(true)).to eq(0)
      expect(alice.reload.balance).to eq(1100)
      expect(bob.reload.balance).to eq(1100)
    end
  end
end
