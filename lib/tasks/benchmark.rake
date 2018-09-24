# frozen_string_literal: true

require 'benchmark/ips'

desc 'Run benchmarks'
task benchmark: :environment do
  create_accounts

  header('Alice & Bob (very high probability of lock waiting & deadlocks)')
  benchmark(:alice_n_bob)

  header('Random accounts (very low probability of lock waiting & deadlocks)')
  benchmark(:random_accounts)
end

# rubocop:disable Metrics/MethodLength
def alice_n_bob(transfer_class, account_class = Account)
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

def random_accounts(transfer_class, account_class = Account)
  threads = Array.new(available_db_connections) do
    Thread.new do
      acc1 = account_class.find_by!(name: "acc#{rand(1000)}")
      acc2 = account_class.find_by!(name: "acc#{rand(1000)}")
      transfer_class.call(acc1, acc2, 1, true)
    end
  end

  threads.each(&:join)
end

def available_db_connections
  ActiveRecord::Base.connection.pool.size - 1
end

def header(title)
  puts '=' * 80
  puts title
  puts "using #{available_db_connections} threads"
  puts '=' * 80
end

def create_accounts
  Account.find_or_create_by(name: 'Alice').update(balance: 1_000_000_000)
  Account.find_or_create_by(name: 'Bob').update(balance: 1_000_000_000)
  OptLockAccount.find_or_create_by(name: 'Alice').update(balance: 1_000_000_000)
  OptLockAccount.find_or_create_by(name: 'Bob').update(balance: 1_000_000_000)

  1000.times do |i|
    Account.find_or_create_by(name: "acc#{i}").update(balance: 1_000_000_000)
    OptLockAccount.find_or_create_by(name: "acc#{i}").update(balance: 1_000_000_000)
  end
end

# rubocop:disable Metrics/MethodLength
def benchmark(method)
  Benchmark.ips do |x|
    x.config(warmup: 0, time: 15)

    x.report('v6 (lock ordering)') do
      send(method, TransferBalance::V6)
    end

    x.report('v7 (retry on deadlock)') do
      send(method, TransferBalance::V7)
    end

    x.report('v8 (repeatable read)') do
      send(method, TransferBalance::V8)
    end

    x.report('v9 (serializable)') do
      send(method, TransferBalance::V9)
    end

    x.report('opt_lock_v1 (retry on deadlock)') do
      send(method, TransferBalance::OptLockV1, OptLockAccount)
    end

    x.compare!
  end
end
# rubocop:enable Metrics/MethodLength
