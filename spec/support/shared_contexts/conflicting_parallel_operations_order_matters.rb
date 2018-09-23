# frozen_string_literal: true

shared_context 'conflicting parallel operations, order matters' do |account_class = Account|
  let(:alice) { account_class.create(name: 'Alice', balance: 100) }
  let(:bob) { account_class.create(name: 'Bob', balance: 100) }

  before do
    alice # create Alice
    bob # create Bob
  end

  it 'fails all but first one' do
    aggregate_failures do
      expect(ActiveRecord::Base.connection.pool.size).to be > 4
      available_db_connections = ActiveRecord::Base.connection.pool.size - 1

      fails = Array.new(available_db_connections) { false }

      threads = Array.new(available_db_connections) do |i|
        Thread.new do
          alice = account_class.find_by!(name: 'Alice')
          bob = account_class.find_by!(name: 'Bob')
          begin
            if i.zero?
              described_class.call(bob, alice, 100)
            else
              # allow first transfer to start first
              sleep(0.01)
              described_class.withdraw(bob, 100)
            end
          rescue ActiveRecord::RecordInvalid
            fails[i] = true
          end
        end
      end

      threads.each(&:join)
      expect(fails.count(true)).to eq(available_db_connections - 1)
      expect(alice.reload.balance).to eq(200)
      expect(bob.reload.balance).to eq(0)
    end
  end
end
