require 'spec_helper'
require 'support/click_session_runner'

describe ClickSession::Configuration do
  context 'no congifuration given' do
    before do
      ClickSession.configure
    end

    it 'provides defaults' do
      expect(ClickSession.configuration.runner_class).to eq(ClickSessionRunner)
      expect(ClickSession.configuration.serializer_class).to eq(ClickSession::WebhookModelSerializer)
      expect(ClickSession.configuration.notifier_class).to eq(ClickSession::Notifier)
      expect(ClickSession.configuration.driver_client).to eq(:poltergeist)
      expect(ClickSession.configuration.screenshot_enabled?).to eq(false)
      expect{ ClickSession.configuration.screenshot }.to raise_error
    end

    it 'raises a helpful error if model_class_name is undefined' do
      expect { ClickSession.configuration.model_class }.
        to raise_error(NameError, %r{https://github\.com/talltorp/click_session})
    end

    it 'raises a helpful error if ClickSessionRunner is undefined' do
      allow(Kernel).to receive_messages(const_defined?: false)

      expect { ClickSession.configuration.runner_class }.
        to raise_error(NameError, %r{https://github\.com/talltorp/click_session})
    end
  end

  context 'with config block' do
    after do
      ClickSession.configure
    end

    it "stores the model_class" do
      class DummyModelClass
      end

      ClickSession.configure do | config |
        config.model_class = DummyModelClass
      end

      expect(ClickSession.configuration.model_class).to eq(DummyModelClass)
    end

    it "stores the runner_class" do
      class DummyProcessorClass
      end

      ClickSession.configure do | config |
        config.runner_class = DummyProcessorClass
      end

      expect(ClickSession.configuration.runner_class).to eq(DummyProcessorClass)
    end

    it "stores the serializer_class" do
      class DummySerializerClass
      end

      ClickSession.configure do | config |
        config.serializer_class = DummySerializerClass
      end

      expect(ClickSession.configuration.serializer_class).to eq(DummySerializerClass)
    end

    it "stores the notifier_class" do
      class DummyNotifierClass < ClickSession::Notifier
      end

      ClickSession.configure do | config |
        config.notifier_class = DummyNotifierClass
      end

      expect(ClickSession.configuration.notifier_class).to eq(DummyNotifierClass)
    end

    context 'when the provided notifier_class does not extend the base Notifier' do
      it "raises an helpful message" do
        class SerializerNotExtendingBaseNotifer
          def session_successful
          end
        end

        ClickSession.configure do | config |
          config.notifier_class = SerializerNotExtendingBaseNotifer
        end

        expect{ ClickSession.configuration.notifier_class }.
          to raise_error(ArgumentError)
      end
    end

    it "stores the driver_client" do
      ClickSession.configure do | config |
        config.driver_client = :selenium
      end

      expect(ClickSession.configuration.driver_client).to eq(:selenium)
    end

    it "stores the enable_screenshot flag" do
      ClickSession.configure do | config |
        config.enable_screenshot = true
      end

      expect(ClickSession.configuration.screenshot_enabled?).to eq(true)
    end

    context 'with complete screenshot information' do
      it "stores the screenshot information" do
        ClickSession.configure do | config |
          config.screenshot = {
            s3_bucket: "unit-bucket",
            s3_key_id: "unit-key-id",
            s3_access_key: "unit-access-key",
          }
        end

        expect(ClickSession.configuration.screenshot).not_to be_nil
      end
    end

    context 'with incomplete screenshot information' do
      context 'with no :s3_bucket' do
        it "raises an ArgumentError" do
          expect do
            ClickSession.configure do | config |
              config.screenshot = {
                s3_key_id: "unit-key-id",
                s3_access_key: "unit-access-key",
              }
            end
          end.to raise_error(ArgumentError)
        end
      end

      context 'with no :s3_key_id' do
        it "raises an ArgumentError" do
          expect do
            ClickSession.configure do | config |
              config.screenshot = {
                s3_bucket: "unit-bucket",
                s3_access_key: "unit-access-key",
              }
            end
          end.to raise_error(ArgumentError)
        end
      end

      context 'with no :s3_access_key' do
        it "raises an ArgumentError" do
          expect do
            ClickSession.configure do | config |
              config.screenshot = {
                s3_bucket: "unit-bucket",
                s3_key_id: "unit-key-id",
              }
            end
          end.to raise_error(ArgumentError)
        end
      end
    end
  end
end