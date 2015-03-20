module ClickSession
  class WebhookModelSerializer
    def serialize(model)
      model.as_json
    end
  end
end