class CreateOptLockAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :opt_lock_accounts do |t|
      t.string :name, null: false
      t.integer :balance, null: false
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :opt_lock_accounts, :name, unique: true
  end
end
