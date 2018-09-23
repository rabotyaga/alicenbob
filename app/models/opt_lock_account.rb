class OptLockAccount < ApplicationRecord
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  def withdraw(amount)
    update!(balance: balance - amount)
  end

  def deposit(amount)
    update!(balance: balance + amount)
  end

  def self.transfer(from, to, amount)
    transaction do
      from.withdraw(amount)
      to.deposit(amount)
    end
  end
end
