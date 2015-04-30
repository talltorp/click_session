# click_session
Turn any repeatable web navigation process into an api

## Why? 
Modern web apps rely more and more on html to be loaded asyncronously after the page has been loaded. The current solutions for automating a series of clicks, form posts and navigation changes relies on all html being rendered at once.

The Capybara team has put a lot of thought into how these web apps can be tested and because of this, it also makes a good tool for scraping these web sites.

## Installation

## How to set up
Add to `Gemfile`
```gem "click_session"``` 

Run `bundle install`

### Generate a migration
`rails generate click_session:install`
This will create a migration and generate an initializer with configuration parameters needed for click_session

### Define the steps in a class
Name the class ```ClickSessionRunner``` and add a method called ```run```.  

This class must extend the ```WebRunner``` class

The ```model``` is an ActiveRecord model which holds the data needed for the session. 

```ruby
class ClickSessionRunner < ClickSession::WebRunner
  
  # Steps to simulate
  def run(model)
    visit "https://www.stackoverflow.com"
    fill_in "q", with: "Capybara"
    press_enter_to_submit

    model.name = first_search_result.text

    model.save
  end

  private

  def press_enter_to_submit
    find_field('q').native.send_key(:enter)
  end

  def first_search_result
    page.first(".summary")
  end
end
```

### Run session syncronously
__Note:__ The response time for this type of request is totally dependant of the time it takes to visit all the pages. 

```ruby
user = User.new
sync_click_session = ClickSession::Sync.new(user)
result = sync_click_session.run
# --> saves the User
# --> run the steps in the ClickSessionRunner
# --> result contains the serialized user data 
```

### Run session asyncronously
```ruby
user = User.new
async_click_session = ClickSession::Async.new(user)
result = async_click_session.run 
# --> saves the User
# --> saves the SessionState
# --> result contains the ID of the saved SessionState

# $ rake click_session:process_active
# --> run the steps in the ClickSessionRunner

# $ rake click_session:report_successful
# --> the request sent contains the serialized user data 
```

### result hash
Example:
```
{
  id: 1234,   
  status: {
    success: true,          # Boolean
  },
  data: {                   # This is the output of the Serialized model
    name: "Joe",
    facebook_avatar: "http://fb.com/i/joe.png"
  }
}
```
The only optional part of the result is the ```data```.

### Example of how to use it in a rails controller action
```ruby
def show
  user = User.new
  sync_click_session = ClickSession::Sync.new(user)
  
  result = sync_click_session.run

  if result.status.success
    render json: result.as_json, status: 201
  else
    render json: result.as_json, status: :unprocessable_entity
  end
end

```

## Mandatory configurations
```ruby
ClickSession.configure do | config |
  config.model_class = YourModel
end
```

## Optional configurations and extentions

```ruby
ClickSession.configure do | config |
  config.web_runner_class = MyCustomRunner 
  config.notifier_class = MyCustomNotifier
  config.serializer_class = MyCustomSerializer
  config.success_callback_url = "https://my.domain.com/webhook_success"
  config.failure_callback_url = "https://my.domain.com/webhook_failure"
  config.enable_screenshot = false # true
  config.screenshot = {
    s3_bucket: ENV['S3_BUCKET'],
    s3_key_id: ENV['S3_KEY_ID'],
    s3_access_key: ENV['S3_ACCESS_KEY']
  }
  config.driver_client = :poltergeist # :selenium
end
```

Option  | Description 
------- | ------------
```notifier_class``` | The name of the class with your [custom notifications](#define-how-you-want-to-be-notified)
```serializer_class``` | The name of the class with your [custom serializer](#define-how-you-want-to-serialize-the-result)
```success_callback_url``` | The url you want us to ```POST``` to with the  successful result.  Only needed when using ```AsyncClickSession```
```failure_callback_url``` | The url you want us to ```POST``` to with the error message.  Only needed when using ```AsyncClickSession```
```enable_screenshot``` | Must be set to true if you want to save screenshots.
```screenshot``` | A hash containing the configuration information needed to be able to save screenshots. ```s3_bucket```, ```s3_key_id``` and ```s3_access_key``` are all required.
```driver_client``` | The driver you want to use to run the ClickSession. ```:poltergeist``` is the default, but ```:selenium``` is a good choice if you are developing in a local environment and want to see the browser appear.


### Define how you want to serialize the result
The serializer class takes the ```model``` that you accociated with the click_session and lets you transform it to whatever structure you like.  

If you don't specify this class, we do a simple ```.as_json``` of the model and return that as the serialized result.

This can be good when there might be things that you save on the model that are not needed in the result, such as generated tokens or simple placeholders of data.

```ruby
class MyUserSerializer
  def serialize(model)
    api_user = {
      name: model.name,
      facebook_avatar: model.user_image
    }

    api_user.as_json
  end
end
```

### Define how you want to be notified
We will notify you when the following things happen
* The ClickSession was successfully completed
* The ClickSession failed because the max number of retries to run the SessionRunner has been exceeded
* The status of the ClickSession was successfully reported back to the webhook
* The max number of retries to report the asyncronous result (success or failure) back to your web hook has been exceeded.
* Every time we rescue an error

If this class is not defined, the information is logged to ```stdout```

All of these notifications are executed after the model has been successfully persisted. 

```ruby
# Override any number of methods to 
# customize the behaviour of the notifications

class MyCustomNotifier < ClickSession::Notifier
  def session_successful(session)
    # Post to slack channel
    # Send an email to the boss
    super # log to stdout
  end

  def session_failed(session)
    # Post to "alerts" channel on slack
    # Send email to developers
  end

  def session_reported(session)
    # Post to slack
  end

  def session_failed_to_report(session)
    # Send email to developers
    # Alert operations!
  end

  def rescued_error(e)
    # Send the error to airbrake
  end
end
```

All other types of possible errors must be handled by your own code.

### Save screen shots to S3
If you have enabled screenshots in your configuration, we will take a screenshot after the run has been successful or failed.

__Note:__ This requires you to add the S3 credentials and bucket name to the configuration


## Rake tasks
### click_session:process_active
Processes all the active click sessions, meaning the ones that are ready to be run.

__Note:__ Only needed for ```ClickSession::Async```

### click_session:report_succesful
Reports all click_sessions, which were successfully run, to the configured ```success_callback_url```

__Note:__ Only needed for ```ClickSession::Async```

### click_session:report_failed
Reports all click_sessions, which failed to run, to the configured ```failure_callback_url```

__Note:__ Only needed for ```ClickSession::Async```

### click_session:report_failed
Reports all click_sessions, which failed to run, to the configured ```failure_callback_url```

__Note:__ Only needed for ```ClickSession::Async```

### click_session:validate (not yet implemented)
Runs the steps you defined that validates that the steps in the session has not changed.

```ruby
class ClickSessionRunner < WebRunner
  def run(search_result_model)
    # ...
  end

  def validate(model)
    visit "http://www.google.com"

    unless search_field_accesible?
      raise ValidateClickSessionError("There are no results!!")
    end
  end

  private
  def search_field_accesible?
    page.find("input[name='query']") != nil
  end
end
```

## Dependencies
This gem is dependant on you having a browser installed which can be run by the capybara driver.

We have tested it with
* poltergeist (PhantomJS)
* selenium (FireFox)

## Deployment
If you like to deploy your code to heroku, you need to use the ```build-pack-multi```.

Create a file in the root of your application called ```.buildpacks```with this content
```
https://github.com/stomita/heroku-buildpack-phantomjs
https://github.com/heroku/heroku-buildpack-ruby
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/click_session/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
