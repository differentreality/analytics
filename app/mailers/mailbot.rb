class Mailbot < ActionMailer::Base
  helper :application

  def noreply
    ENV['sender_for_emails']
  end

end
