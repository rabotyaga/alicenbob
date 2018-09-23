# frozen_string_literal: true

module TransferBalance
  # transaction w/ locks everywhere
  # no lost updates
  # guarantees same order
  # avoids deadlock by rescue w/ retry
  module V7
    class << self
      def call(from, to, amount)
        ActiveRecord::Base.transaction do
          from.lock!

          # give a chance for a deadlock
          sleep(0.01)

          to.lock!

          # emulate some heavy-lifting stuff
          # giving a chance for standalone #withdraw / #deposit finish first
          sleep(0.05)

          withdraw(from, amount)
          deposit(to, amount)
        end
      rescue ActiveRecord::Deadlocked
        retry
      end

      def withdraw(from, amount)
        from.with_lock { from.update!(balance: from.balance - amount) }
      end

      def deposit(to, amount)
        to.with_lock { to.update!(balance: to.balance + amount) }
      end
    end
  end
end
