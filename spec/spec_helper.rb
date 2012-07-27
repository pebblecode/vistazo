# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative 'support/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'ruby-debug'
require 'capybara/rspec'
require 'email_spec'

require 'support/omniauth'
require 'support/mongodb'
require 'support/path'

# Include in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec

  conf.include(EmailSpec::Helpers)
  conf.include(EmailSpec::Matchers)

  conf.include OmniauthSpecHelper
  conf.include MongoDBSpecHelper
  conf.include PathSpecHelper

  conf.before(:each) do
    do_not_send_email
  end
end

Capybara.save_and_open_page_path = "./tmp"

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end

def http_authorization_capybara!
  auth_string = Base64.encode64("vistazo:vistazo").gsub(/ /, '')
  driver = Capybara.current_session.driver
  driver.header "Authorization", "Basic #{auth_string}"
end

def do_not_send_email
  Pony.stub!(:deliver)  # Hijack deliver method to not send email
end

def should_be_on_team_name_page(team_name)
  find("#team-name").text.should include(team_name)
end

def should_not_be_on_team_name_page(team_name)
  find("#team-name").text.should_not include(team_name)
end

# Extract the backbone collection on the page from the javascript
# `reset` call. This would be the final point to access the data
# before it gets used by javascript.
#
# Return a hash of the collection
def backbone_collection_on_page(collection_name, page)
  coll_string = case collection_name
                when :users
                  /App.users.reset\((\[.*\])\)/.match(page.body)[1]
                when :projects
                  /App.projects.reset\((\[.*\])\)/.match(page.body)[1]
                when :user_timetables
                  /App.userTimetables.reset\((\[.*\])\)/.match(page.body)[1]
                end

  ActiveSupport::JSON.decode(coll_string)
end

# Define application for all spec files
def app
  Sinatra::Application
end
Capybara.app = VistazoApp