# Parameters:
#
# from_email
# to_email
# subject
# body
# 
# required params:
# => address
# => user_name
# => password
# => domain
def send_email(from_email, to_email, subject, body, params)
  default_options = {
    :port           => "25",
    :authentication => :plain
  }
  
  extra_options = default_options.merge(params)
  
  Pony.mail :to => to_email,
            :from => from_email,
            :subject => subject,
            :body => body,
	    :charset => 'utf-8',
            :via => :smtp,
            :via_options => extra_options
end

def send_google_email(from_email, to_email, subject, body)
  email_params = {
    :address => "smtp.gmail.com",
    :domain => "vistazoapp.com",
    :port => '587',
    :enable_starttls_auto => true,
    :user_name => APP_CONFIG["google_user_name"],
    :password => APP_CONFIG["google_password"]
  }

  send_email(from_email, to_email, subject, body, email_params)
end

def send_sendgrid_email(from_email, to_email, subject, body)
  email_params = {
    :address => "smtp.sendgrid.net",
    :user_name => ENV['SENDGRID_USERNAME'] || APP_CONFIG['email_service_username'],
    :password => ENV['SENDGRID_PASSWORD'] || APP_CONFIG['email_service_password'],
    :domain => APP_CONFIG['email_service_domain'],
    :port => '587',
    :authentication => :plain,
    :enable_starttls_auto => true
  }

  send_email(from_email, to_email, subject, body, email_params)
end
