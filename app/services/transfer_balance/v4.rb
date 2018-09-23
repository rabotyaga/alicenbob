# frozen_string_literal: true

module TransferBalance
  # transaction w/ locks in #withdraw / #deposit
  # no lost updates
  # does not guarantee same order
  module V4
    class << self
      def call(from, to, amount)
        ActiveRecord::Base.transaction do
          # emulate some heavy-lifting stuff
          # giving a chance for standalone #withdraw / #deposit finish first
          sleep(0.05)

          withdraw(from, amount)
          deposit(to, amount)
        end
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
