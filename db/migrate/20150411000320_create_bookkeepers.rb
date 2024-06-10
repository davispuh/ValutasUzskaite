class CreateBookkeepers < ActiveRecord::Migration
    def change
        create_table :bookkeepers do |t|
            t.string :Vārds, limit: 100, index: true, null: false
            t.string :Epasts, limit: 255, index: true
            t.string :Parole, limit: 100
            t.boolean :Bloķēts
            t.timestamp :created_at
        end
    end
end
