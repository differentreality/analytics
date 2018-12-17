source 'https://rubygems.org'

# ruby '2.4.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

gem 'pg', '~> 0.21'
gem 'sqlite3'

# Use haml as templating language
gem 'haml-rails'
gem "font-awesome-sass"

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# Use bootstrap as the front-end framework
gem 'bootstrap-sass', '~> 3.3.7'
gem 'formtastic-bootstrap'
gem 'formtastic'

gem 'bootstrap-datepicker-rails'

# for switch checkboxes
gem 'bootstrap-switch-rails'

gem 'jquery-datatables-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'momentjs-rails', '>= 2.8.1'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# to show flash messages from ajax requests
gem 'unobtrusive_flash', '>=3'
gem 'validates_email_format_of'

# as authentification framework
gem 'devise', '~> 4.2.0'
gem 'devise-i18n'

# to support openID authentication
gem 'omniauth'
gem 'omniauth-facebook'

# For charts
gem 'chartkick'
gem 'groupdate'

gem 'cocoon'
gem 'validate_url'

gem 'rmagick'

gem 'activerecord-native_db_types_override'

# Puma web server for production
gem 'puma'

gem 'dotenv-rails'
# scheduler
gem 'rufus-scheduler'

gem 'cancancan'
gem 'wicked_pdf'

gem 'koala'

group :production do
  # Use exception_notification to receive emails on errors
  gem 'exception_notification'
  gem 'rails_12factor'
end

group :development do
  # Use letter_opener for opening emails in browser
  gem 'letter_opener'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #  gem 'spring'
  #  gem 'guard'
end

group :test do
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
  gem 'database_cleaner'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'factory_girl_rails'
  gem 'tzinfo-data'
  gem 'capybara'

  # for styling
  gem 'rubocop'
end
