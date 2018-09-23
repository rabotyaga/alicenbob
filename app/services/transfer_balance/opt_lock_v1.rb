# frozen_string_literal: true

module TransferBalance
  # transaction w/ optimistic locks
  # no lost updates
  # retries on ActiveRecord::StaleObjectError
  # does not guarantee same order
  # can (and will!) raise ActiveRecord::Deadlocked
  module OptLockV1
    class << self
      def call(from, to, amount)
        ActiveRecord::Base.transaction do
          # emulate some heavy-lifting stuff
          # giving a chance for standalone #withdraw / #deposit finish first
          sleep(0.05)

          withdraw(from, amount)
          deposit(to, amount)
        end
      rescue ActiveRecord::StaleObjectError
        retry
      end

      def withdraw(from, amount)
        from.update!(balance: from.balance - amount)
      rescue ActiveRecord::StaleObjectError
        retry
      end

      def deposit(to, amount)
        to.update!(balance: to.balance + amount)
      rescue ActiveRecord::StaleObjectError
        retry
      end
    end
  end
end
