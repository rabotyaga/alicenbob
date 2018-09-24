# frozen_string_literal: true

module TransferBalance
  # transaction w/ optimistic locks
  # no lost updates
  # retries on ActiveRecord::StaleObjectError & deadlocks
  # does not guarantee same order
  module OptLockV1
    class << self
      def call(from, to, amount, skip_sleep = false)
        ActiveRecord::Base.transaction do
          # emulate some heavy-lifting stuff
          # giving a chance for standalone #withdraw / #deposit finish first
          sleep(0.05) unless skip_sleep

          withdraw(from, amount)
          deposit(to, amount)
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::StaleObjectError
        retry
      end

      def withdraw(from, amount)
        from.update!(balance: from.balance - amount)
      rescue ActiveRecord::StaleObjectError
        from.reload
        retry
      end

      def deposit(to, amount)
        to.update!(balance: to.balance + amount)
      rescue ActiveRecord::StaleObjectError
        to.reload
        retry
      end
    end
  end
end
