# frozen_string_literal: true

require 'benchmark/ips'

desc 'Run benchmarks'
task benchmark: :environment do
  Account.find_or_create_by(name: 'Alice').update(balance: 1000)
  Account.find_or_create_by(name: 'Bob').update(balance: 1000)
  OptLockAccount.find_or_create_by(name: 'Alice').update(balance: 1_000_000)
  OptLockAccount.find_or_create_by(name: 'Bob').update(balance: 1_000_000)

  puts '=' * 80
  puts 'Alice & Bob (very high probability of lock waiting & deadlocks)'

  Benchmark.ips do |x|
    x.config(warmup: 0, time: 15)

    x.report('v6 (lock ordering)') do
      run(TransferBalance::V6)
    end

    x.report('v7 (rescue ActiveRecord::Deadlocked & retry)') do
      run(TransferBalance::V7)
    end

    x.report('v8 (repeatable read isolation level)') do
      run(TransferBalance::V8)
    end

    x.report('v9 (serializable isolation level)') do
      run(TransferBalance::V9)
    end

    x.report('opt_lock_v1 (optimistic locks & retry on deadlocks)') do
      run(TransferBalance::OptLockV1, OptLockAccount)
    end

    x.compare!
  end

  1000.times do |i|
    Account.find_or_create_by(name: "acc#{i}").update(balance: 1_000_000)
    OptLockAccount.find_or_create_by(name: "acc#{i}").update(balance: 1_000_000)
  end

  puts '=' * 80
  puts 'Random accounts (very low probability of lock waiting & deadlocks)'

  Benchmark.ips do |x|
    x.config(warmup: 0, time: 15)

    x.report('v6 (lock ordering)') do
      run2(TransferBalance::V6)
    end

    x.report('v7 (rescue ActiveRecord::Deadlocked & retry)') do
      run2(TransferBalance::V7)
    end

    x.report('v8 (repeatable read isolation level)') do
      run2(TransferBalance::V8)
    end

    x.report('v9 (serializable isolation level)') do
      run2(TransferBalance::V9)
    end

    x.report('opt_lock_v1 (optimistic locks & retry on deadlocks)') do
      run2(TransferBalance::OptLockV1, OptLockAccount)
    end

    x.compare!
  end
end

# rubocop:disable Metrics/MethodLength
def run(transfer_class, account_class = Account)
  available_db_connections = ActiveRecord::Base.connection.pool.size - 1

  threads = Array.new(available_db_connections) do |i|
    Thread.new do
      alice = account_class.find_by!(name: 'Alice')
      bob = account_class.find_by!(name: 'Bob')
      if i.even?
        transfer_class.call(bob, alice, 1, true)
      else
        transfer_class.call(alice, bob, 1, true)
      end
    end
  end

  threads.each(&:join)
end
# rubocop:enable Metrics/MethodLength

def run2(transfer_class, account_class = Account)
  available_db_connections = ActiveRecord::Base.connection.pool.size - 1

  threads = Array.new(available_db_connections) do
    Thread.new do
      acc1 = account_class.find_by!(name: "acc#{rand(1000)}")
      acc2 = account_class.find_by!(name: "acc#{rand(1000)}")
      transfer_class.call(acc1, acc2, 1, true)
    end
  end

  threads.each(&:join)
end
