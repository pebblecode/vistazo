source :rubyforge
gem 'rake'
gem 'sinatra'
gem 'thin'
gem 'sinatra-flash'
gem 'json'

# Fix rack version for now because of #156
gem 'rack', '1.3.5'
# Living on the edge!
# gem 'rack'


# Views
gem 'sass'

# For production deployment
gem 'heroku'

# Mongo db
# gem 'mongo_mapper'
gem 'mongo_mapper', :git => 'http://github.com/pebblecode/mongomapper.git'
gem 'bson_ext'

# Authentication
gem 'omniauth'
gem 'omniauth-google-oauth2'

# Email
gem 'pony'

# New relic
gem 'newrelic_rpm'

# Redirect domains
gem "rack-force_domain"

group :development, :test do
  # Servers
  gem 'shotgun'
  gem 'ruby-debug19', :require => 'ruby-debug'

  # Testing
  gem 'guard'
  gem 'foreman'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem 'guard-rspec'
  # gem 'guard-minitest'
  # gem 'minitest'
  gem 'rspec'
  gem 'email_spec'
  gem 'rack-test'
  gem "factory_girl", "~> 2.1.0"
  gem 'capybara'
  gem 'jasmine'

  # Tux, console like
  gem 'tux'
end

