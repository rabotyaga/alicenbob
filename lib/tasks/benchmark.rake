# frozen_string_literal: true

require 'benchmark/ips'

desc 'Run benchmarks'
task benchmark: :environment do
  alice = Account.find_or_create_by(name: 'Alice')
  bob = Account.find_or_create_by(name: 'Bob')
  alice.update(balance: 1000)
  bob.update(balance: 1000)

  Benchmark.ips do |x|
    x.config(warmup: 0, time: 5)

    x.report('v6 (lock ordering)') do
      run(TransferBalance::V6)
    end

    x.report('v7 (rescue ActiveRecord::Deadlocked & retry)') do
      run(TransferBalance::V7)
    end

    x.compare!
  end
end

# rubocop:disable Metrics/MethodLength
def run(service_class = TransferBalance::V6)
  available_db_connections = 4

  fails = Array.new(available_db_connections) { false }

  threads = Array.new(available_db_connections) do |i|
    Thread.new do
      alice = Account.find_by!(name: 'Alice')
      bob = Account.find_by!(name: 'Bob')
      begin
        if i.even?
          service_class.call(bob, alice, 100, true)
        else
          service_class.call(alice, bob, 100, true)
        end
      rescue ActiveRecord::RecordInvalid
        fails[i] = true
      end
    end
  end

  threads.each(&:join)
end
# rubocop:enable Metrics/MethodLength
