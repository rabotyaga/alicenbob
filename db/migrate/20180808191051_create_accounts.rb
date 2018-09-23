class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :balance, null: false

      t.timestamps
    end

    add_index :accounts, :name, unique: true
  end
end
