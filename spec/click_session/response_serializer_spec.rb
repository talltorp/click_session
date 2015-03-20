require 'spec_helper'
require "click_session/configuration"
require 'support/test_unit_model'

describe ClickSession::ResponseSerializer do
  let(:session_state) { ClickSession::SessionState.create }

  let(:model) {
    create(:test_unit_model)
  }

  describe "#serialize_success" do
    before do
      mock_configuration_model_class_with(model)
    end

    context 'With the default serializer' do
      it "returns success meta data with the model serialized" do
        session_state.model = model
        response_serializer = ClickSession::ResponseSerializer.new

        response = response_serializer.serialize_success(session_state)

        expect(response).to eql({
          id: session_state.id,
          status: {
            success: true
          },
          data: model.as_json
        })
      end
    end
  end

  describe "#serialize_failure" do
    it "returns failure meta data and no serialized model" do
      session_state.model = model
      response_serializer = ClickSession::ResponseSerializer.new

      response = response_serializer.serialize_failure(session_state)

      expect(response).to eql({
        id: session_state.id,
        status: {
          success: false
        }
      })
    end
  end
end