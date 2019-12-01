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

ActiveRecord::Schema.define(version: 20191201073903) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "age_fans", force: :cascade do |t|
    t.integer  "gender"
    t.integer  "age_range"
    t.integer  "count"
    t.datetime "date"
    t.integer  "page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ahoy_messages", force: :cascade do |t|
    t.string   "token"
    t.text     "to"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "mailer"
    t.text     "subject"
    t.text     "content"
    t.string   "utm_source"
    t.string   "utm_medium"
    t.string   "utm_term"
    t.string   "utm_content"
    t.string   "utm_campaign"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.integer  "customer_id"
    t.index ["token"], name: "index_ahoy_messages_on_token", using: :btree
    t.index ["user_id", "user_type"], name: "index_ahoy_messages_on_user_id_and_user_type", using: :btree
  end

  create_table "city_fans", force: :cascade do |t|
    t.text     "country"
    t.text     "municipality"
    t.text     "province"
    t.integer  "count"
    t.integer  "page_id"
    t.date     "date"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "name"
    t.string   "object_id"
    t.integer  "shares"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "posted_at"
    t.integer  "page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_events_on_page_id", using: :btree
  end

  create_table "openids", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "email"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: :cascade do |t|
    t.string  "name"
    t.string  "object_id"
    t.integer "fans"
    t.boolean "default",   default: false
  end

  create_table "pages_users", force: :cascade do |t|
    t.integer  "page_id"
    t.integer  "user_id"
    t.string   "access_token"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "people", force: :cascade do |t|
    t.string   "name"
    t.string   "object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text     "message"
    t.string   "object_id"
    t.integer  "shares"
    t.integer  "kind"
    t.datetime "posted_at"
    t.integer  "page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "story"
    t.index ["page_id"], name: "index_posts_on_page_id", using: :btree
  end

  create_table "reactions", force: :cascade do |t|
    t.string   "reactionable_type"
    t.integer  "reactionable_id"
    t.string   "name"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.datetime "posted_at"
    t.integer  "page_id"
    t.integer  "person_id"
    t.index ["reactionable_type", "reactionable_id"], name: "index_reactions_on_reactionable_type_and_reactionable_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

end
