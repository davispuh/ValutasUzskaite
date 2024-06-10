# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150411002016) do

  create_table "amounts", force: :cascade do |t|
    t.integer "currency_id", null: false
    t.integer "Apjoms"
  end

  create_table "bookkeepers", force: :cascade do |t|
    t.string   "V\u0101rds",        limit: 100, null: false
    t.string   "Epasts",            limit: 255
    t.string   "Parole",            limit: 100
    t.boolean  "Blo\u0137\u0113ts"
    t.datetime "created_at"
  end

  add_index "bookkeepers", ["Epasts"], name: "index_bookkeepers_on_Epasts"
  add_index "bookkeepers", ["V\u0101rds"], name: "index_bookkeepers_on_V\u0101rds"

  create_table "currencies", force: :cascade do |t|
    t.string "Apz\u012Bm\u0113jums", limit: 10, null: false
    t.string "Nosaukums",            limit: 50
  end

  add_index "currencies", ["Apz\u012Bm\u0113jums"], name: "index_currencies_on_Apz\u012Bm\u0113jums"

end
