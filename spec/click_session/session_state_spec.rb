require "spec_helper"
require "click_session/configuration"
require 'support/test_unit_model'

describe ClickSession::SessionState do
  let(:model) { create(:test_unit_model) }

  it { should validate_presence_of(:model_record) }

  describe "#webhook_attempt_failed" do
    it "increments the number of attempts" do
      execution_state = ClickSession::SessionState.new

      execution_state.webhook_attempt_failed

      expect(execution_state.webhook_attempts).to eql(1)
    end
  end

  describe "#model" do
    context 'When model_class has been configured' do
      before do
        mock_configuration_model_class_with(model)
      end

      context 'with id to the record' do
        it "returns the active record for the configured model_name" do
          session_state = ClickSession::SessionState.create(model: model.id)

          expect(session_state.model).to be_a(TestUnitModel)
        end
      end

      context 'with an actual active record class' do
        it "returns the active record for the configured model_name" do
          session_state = ClickSession::SessionState.create(model: model)

          expect(session_state.model).to be_a(TestUnitModel)
        end
      end

      context 'When model passed is new' do
        it "saves the model along with the session state" do
          allow(model).to receive(:save!)
          allow(model).to receive(:new_record?).and_return(true)

          session_state = ClickSession::SessionState.create(model: model)

          expect(model).to have_received(:save!)
        end
      end
    end
  end
end