require 'state_machine'
require 'active_record'

module ClickSession
  class SessionState < ActiveRecord::Base
    validates :model_record, presence: true

    state_machine initial: :active do
      state :active, value: 0
      state :processed, value: 1
      state :success_reported, value: 10
      state :failed_to_process, value: 2
      state :failure_reported, value: 20

      event :success do
        transition active: :processed
      end

      event :failure do
        transition active: :failed_to_process
      end

      event :reported_back do
        transition processed: :success_reported, failed_to_process: :failure_reported
      end
    end

    def model=(model)
      set_model_record_for(model)
    end

    def model
      @model ||= model_class.find_by_id(self.model_record)
    end

    def webhook_attempt_failed
      self.webhook_attempts += 1
    end

    private

    delegate :model_class, to: :clicksession_configuration

    def set_model_record_for(model)
      if model.is_a? Integer
        self.model_record = model
      else
        set_active_record_model_id_for(model)
      end
    end

    def set_active_record_model_id_for(model)
      if model.new_record?
        model.save!
      end

      self.model_record = model.id
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end