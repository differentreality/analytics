# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Load the configuration file
# APP_ENV = YAML.load_file(Rails.root.join('/config.yml'))[Rails.env]

# Load the configuration file
# path = Rails.root.join('config', 'config.yml')
# begin
#   # CONFIG = YAML.load_file(path)[Rails.env]
#   ENV = YAML.load_file(path)[Rails.env]
# rescue
#   puts "Error while parsing config file #{path}"
#   # CONFIG = {}
#   ENV = {}
# end

NativeDbTypesOverride.configure({
  postgres: {
    datetime: { name: "timestamptz" },
    timestamp: { name: "timestamptz" }
  }
})

# Initialize the Rails application.
Rails.application.initialize!
