class ErrorsController < ApplicationController
  # skip_authorization_check
  before_action :html_format

  def error
    render template: 'errors/error'
  end

  private

  ##
  # Always shows format as html
  # So that PDF calls get redirect to the HTML error page
  def html_format
    request.format = :html
  end
end
