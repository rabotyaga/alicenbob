# frozen_string_literal: true

describe TransferBalance::V6 do
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
    it 'raises validation error, both balances stay unchanged' do
      expect { described_class.call(bob, alice, 200) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect(alice.reload.balance).to eq 100
      expect(bob.reload.balance).to eq 100
    end
  end

  context 'with conflicting parallel operations' do
    before do
      alice # create Alice
      bob # create Bob
    end

    it 'fails all but first one' do
      expect(ActiveRecord::Base.connection.pool.size).to be > 4
      available_db_connections = ActiveRecord::Base.connection.pool.size - 1

      fails = Array.new(available_db_connections) { false }

      threads = Array.new(available_db_connections) do |i|
        Thread.new do
          alice = Account.find_by!(name: 'Alice')
          bob = Account.find_by!(name: 'Bob')
          begin
            if i.zero?
              described_class.call(bob, alice, 100)
            else
              # allow first transfer to start first
              # increased sleep time to not accidentally withdraw Bob's account
              # before transfer to Alice actually starts
              sleep(0.06)
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

  context 'with non conflicting parallel operations' do
    before do
      alice.deposit 1000
      bob.deposit 1000
    end

    it 'handles deadlocks' do
      expect(ActiveRecord::Base.connection.pool.size).to be > 4
      available_db_connections = 4

      fails = Array.new(available_db_connections) { false }

      threads = Array.new(available_db_connections) do |i|
        Thread.new do
          alice = Account.find_by!(name: 'Alice')
          bob = Account.find_by!(name: 'Bob')
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
