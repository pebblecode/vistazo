# Parameters:
#
# from_email
# to_email
# subject
# email_erb_view
# 
# required params:
# => address
# => user_name
# => password
# => domain
def send_email(from_email, to_email, subject, email_erb_view, params)
  default_options = {
    :port           => "25",
    :authentication => :plain,
  }
  
  extra_options = default_options.merge(params)
  
  Pony.mail :to => to_email,
            :from => from_email,
            :subject => subject,
            :body => erb(email_erb_view, :layout => false),
            :via => :smtp,
            :via_options => extra_options

end