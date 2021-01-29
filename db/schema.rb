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

ActiveRecord::Schema.define(version: 2020_12_17_162712) do

  create_table "async_processes", force: :cascade do |t|
    t.string "rid"
    t.text "request"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_hash"
    t.integer "store_id"
    t.text "file_list"
    t.text "error_list"
  end

  create_table "billings", force: :cascade do |t|
    t.string "uid"
    t.string "buyer"
    t.string "buyer_pubkey_id"
    t.string "seller"
    t.string "seller_pubkey_id"
    t.text "request"
    t.text "usage_policy"
    t.string "payment_method"
    t.text "buyer_signature"
    t.text "seller_signature"
    t.datetime "offer_timestamp"
    t.float "offer_price"
    t.string "payment_address"
    t.datetime "payment_timestamp"
    t.float "payment_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "buyer_address"
    t.text "offer_info"
    t.text "buyer_info"
    t.string "transaction_hash"
    t.string "transaction_timestamp"
    t.datetime "valid_until"
    t.string "address_path"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "logs", force: :cascade do |t|
    t.text "item"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "read_hash"
    t.string "receipt"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confidential", default: true, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "provenances", force: :cascade do |t|
    t.text "prov"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "input_hash"
    t.datetime "startTime"
    t.datetime "endTime"
    t.string "receipt_hash"
    t.text "scope"
    t.string "revocation_key"
  end

  create_table "semantics", force: :cascade do |t|
    t.text "validation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
  end

  create_table "stores", force: :cascade do |t|
    t.text "item"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prov_id"
    t.string "key"
    t.string "dri"
    t.string "schema_dri"
    t.string "mime_type"
    t.string "table_name"
    t.index ["dri"], name: "index_stores_on_dri"
    t.index ["schema_dri"], name: "index_stores_on_schema_dri"
    t.index ["table_name"], name: "index_stores_on_table_name"
  end

  create_table "watermarks", force: :cascade do |t|
    t.integer "account_id"
    t.string "fragment"
    t.text "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
