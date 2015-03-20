class CreateClickSessions < ActiveRecord::Migration
  def change
    create_table :session_states  do |t|
      t.integer "webhook_attempts", default: 0, null: false
      t.integer "state",            null: false
      t.integer "model_record"
      t.string  "screenshot_url"
      t.timestamps null: false
    end

    add_index :session_states, :model_record, unique: true
  end
end