# frozen_string_literal: true

module TransferBalance
  # transaction w/ repeatable_read isolation level
  # no lost updates
  # does not guarantee same order
  # avoids deadlock by rescue w/ retry
  module V8
    class << self
      def call(from, to, amount, skip_sleep = false)
        ActiveRecord::Base.transaction(options) do
          # emulate some heavy-lifting stuff
          # giving a chance for standalone #withdraw / #deposit finish first
          sleep(0.05) unless skip_sleep

          withdraw(from, amount)
          deposit(to, amount)
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::SerializationFailure
        retry
      end

      def withdraw(from, amount)
        from.transaction(options) do
          from.reload
          from.update!(balance: from.balance - amount)
        end
      rescue ActiveRecord::SerializationFailure
        ActiveRecord::Base.connection.transaction_open? ? raise : retry
      end

      def deposit(to, amount)
        to.transaction(options) do
          to.reload
          to.update!(balance: to.balance + amount)
        end
      rescue ActiveRecord::SerializationFailure
        ActiveRecord::Base.connection.transaction_open? ? raise : retry
      end

      def options
        if ActiveRecord::Base.connection.transaction_open?
          {}
        else
          { isolation: :repeatable_read }
        end
      end
    end
  end
end
