# frozen_string_literal: true

module TransferBalance
  # simple transaction w/o locking, allows lost update
  module V2
    class << self
      def call(from, to, amount)
        ActiveRecord::Base.transaction do
          withdraw(from, amount)
          deposit(to, amount)
        end
      end

      def withdraw(from, amount)
        from.update!(balance: from.balance - amount)
      end

      def deposit(to, amount)
        to.update!(balance: to.balance + amount)
      end
    end
  end
end
