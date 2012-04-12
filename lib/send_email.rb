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

# Send email using google config if not in development mode.
def send_google_email(from_email, to_email, subject, body)
  email_params = {
    :address => "smtp.gmail.com",
    :domain => "vistazoapp.com",
    :port => '587',
    :enable_starttls_auto => true,
    :user_name => APP_CONFIG["google_user_name"],
    :password => APP_CONFIG["google_password"]
  }

  if ENV['RACK_ENV'] == "development"
    logger.info "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
    logger.info "send_from_email: #{from_email}"
    logger.info "send_to_email: #{to_email}"
    logger.info "email_params: #{email_params}"
    logger.info "subject: #{subject}"

    logger.info body
  else
    send_email(from_email, to_email, subject, body, email_params)
  end
end

# Send email using sendgrid config if not in development mode. Also show
# email in logs if in staging mode.
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

  if ENV['RACK_ENV'] == "development"
    logger.info "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
    logger.info "send_from_email: #{from_email}"
    logger.info "send_to_email: #{to_email}"
    logger.info "email_params: #{email_params}"
    logger.info "subject: #{subject}"
            
    logger.info body
  else
    if ENV['RACK_ENV'] == "staging"
      logger.info "STAGING MODE: this email should be sent:"
      logger.info "send_from_email: #{from_email}"
      logger.info "send_to_email: #{to_email}"
      logger.info "email_params: #{email_params}"
      logger.info "subject: #{subject}"
      
      logger.info body
    end
    
    send_email(from_email, to_email, subject, body, email_params)
  end
end
