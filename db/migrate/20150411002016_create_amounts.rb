class CreateAmounts < ActiveRecord::Migration
    def change
        create_table :amounts do |t|
            t.references :currency, null: false
            t.integer :Apjoms
        end
    end
end
