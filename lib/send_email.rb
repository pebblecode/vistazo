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
    :authentication => :plain,
    :charset => 'utf-8'
  }
  
  extra_options = default_options.merge(params)
  
  Pony.mail :to => to_email,
            :from => from_email,
            :subject => subject,
            :body => body,
            :via => :smtp,
            :via_options => extra_options

end
