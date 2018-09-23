# frozen_string_literal: true

module TransferBalance
  # no transactions
  module V0
    class << self
      def call(from, to, amount)
        withdraw(from, amount)
        deposit(to, amount)
      end

      def withdraw(from, amount)
        from.update(balance: from.balance - amount)
      end

      def deposit(to, amount)
        to.update(balance: to.balance + amount)
      end
    end
  end
end
