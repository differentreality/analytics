Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Set the detault url for action mailer
  config.action_mailer.default_url_options = { host: (ENV['HOSTNAME'] || 'localhost:3000') }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true

  config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_ADDRESS'],
    port:                 ENV['SMTP_PORT'],
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       ENV['SMTP_AUTHENTICATION'].try(:to_sym),
    domain:               ENV['SMTP_DOMAIN'],
    enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'],
    openssl_verify_mode:  ENV['SMTP_OPENSSL_VERIFY_MODE']
  }

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default :charset => "utf-8"

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # See everything in the log (default is :info)
  config.log_level =  ENV['LOG_LEVEL'] || 'info'

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.force_ssl = false

  config.serve_static_files = false
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass
  config.assets.compile = false
  config.assets.digest = true
  # for nginx (change it for apache)
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  config.assets.enabled = true
  config.assets.version = '1.0'
  config.secret_key_base ||= ENV["SECRET_KEY_BASE"]
end
