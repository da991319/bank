class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.string :description
      t.float  :amount
      t.date :transaction_date
      t.string :user
      t.boolean :payed , :default => false
      t.date :payed_date
      t.integer :payed_by

      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end
