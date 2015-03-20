ActiveRecord::Schema.define do
  self.verbose = false

  create_table :session_states, :force => true do |t|
    t.integer "webhook_attempts", default: 0, null: false
    t.integer "state",            default: 0, null: false
    t.integer "model_record"
    t.string  "screenshot_url"
    t.timestamps null: false
  end

  create_table :test_unit_models, :force => true do |t|
    t.string  "name"
    t.timestamps null: false
  end
end