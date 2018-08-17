# Create logger that ignores messages containing “CACHE”
class CacheFreeLogger < ::Logger
  def debug(message, *args, &block)
    super unless message.include?('CACHE') || message.include?('Load')
  end
end

# Overwrite ActiveRecord’s logger
ActiveRecord::Base.logger = ActiveSupport::TaggedLogging.new(
  CacheFreeLogger.new(STDOUT)) unless Rails.env.test?
