class CreateCurrencies < ActiveRecord::Migration
    def change
        create_table :currencies do |t|
            t.string :Apzīmējums, limit: 10, index: true, null: false
            t.string :Nosaukums, limit: 50
        end
    end
end
