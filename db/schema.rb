# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_03_054432) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "board_meetings", force: :cascade do |t|
    t.string "topic"
    t.jsonb "guest_ids"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "board_messages", force: :cascade do |t|
    t.bigint "board_meeting_id", null: false
    t.string "sender_type"
    t.bigint "sender_graph_node_id"
    t.text "content"
    t.integer "sequence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_meeting_id"], name: "index_board_messages_on_board_meeting_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.integer "role"
    t.text "content"
    t.json "sources"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.json "context_filters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "content_chunks", force: :cascade do |t|
    t.text "content"
    t.float "start_timestamp"
    t.float "end_timestamp"
    t.vector "embedding", limit: 768
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sourceable_type"
    t.bigint "sourceable_id"
    t.bigint "user_id"
    t.string "visibility"
    t.index ["sourceable_type", "sourceable_id"], name: "index_content_chunks_on_sourceable_type_and_sourceable_id"
    t.index ["user_id", "visibility"], name: "index_content_chunks_on_user_id_and_visibility"
    t.index ["user_id"], name: "index_content_chunks_on_user_id"
    t.index ["visibility"], name: "index_content_chunks_on_visibility"
  end

  create_table "episodes", force: :cascade do |t|
    t.string "guest"
    t.string "title"
    t.string "video_id"
    t.date "publish_date"
    t.text "description"
    t.integer "duration_seconds"
    t.integer "view_count"
    t.string "channel"
    t.string "youtube_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "visibility", default: "public"
    t.index ["user_id"], name: "index_episodes_on_user_id"
    t.index ["visibility"], name: "index_episodes_on_visibility"
  end

  create_table "graph_edges", force: :cascade do |t|
    t.bigint "source_node_id", null: false
    t.bigint "target_node_id", null: false
    t.string "relationship_type"
    t.bigint "content_chunk_id", null: false
    t.jsonb "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_chunk_id"], name: "index_graph_edges_on_content_chunk_id"
    t.index ["source_node_id", "target_node_id", "relationship_type"], name: "index_edges_on_source_target_rel"
    t.index ["source_node_id"], name: "index_graph_edges_on_source_node_id"
    t.index ["target_node_id"], name: "index_graph_edges_on_target_node_id"
  end

  create_table "graph_nodes", force: :cascade do |t|
    t.string "name"
    t.string "label"
    t.text "description"
    t.jsonb "properties"
    t.vector "embedding", limit: 768
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_graph_nodes_on_name"
  end

  create_table "pdf_documents", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id", null: false
    t.string "visibility"
    t.integer "page_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pdf_documents_on_user_id"
  end

  create_table "playbooks", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.jsonb "sources"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_playbooks_on_user_id"
  end

  create_table "slack_exports", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id", null: false
    t.string "visibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_slack_exports_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "web_pages", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.text "content_snapshot"
    t.bigint "user_id", null: false
    t.string "visibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_web_pages_on_user_id"
  end

  create_table "whats_app_chats", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id", null: false
    t.boolean "processed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "private"
    t.index ["user_id"], name: "index_whats_app_chats_on_user_id"
    t.index ["visibility"], name: "index_whats_app_chats_on_visibility"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "board_messages", "board_meetings"
  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "content_chunks", "users"
  add_foreign_key "episodes", "users"
  add_foreign_key "graph_edges", "content_chunks"
  add_foreign_key "graph_edges", "graph_nodes", column: "source_node_id"
  add_foreign_key "graph_edges", "graph_nodes", column: "target_node_id"
  add_foreign_key "pdf_documents", "users"
  add_foreign_key "playbooks", "users"
  add_foreign_key "slack_exports", "users"
  add_foreign_key "web_pages", "users"
  add_foreign_key "whats_app_chats", "users"
end
