class VistazoApp < Sinatra::Application

  get '/:account_id' do
    protected!
  
    @account = Account.find(params[:account_id])
  
    if @account.present?
      redirect "/#{params[:account_id]}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
    else
      flash.next[:warning] = "Invalid account."
      redirect '/'
    end
  end

  post '/:account_id/new-user' do
    puts "New user: #{params}"
    email = params[:new_user_email]
    
    @account = Account.find(params[:account_id])
    if @account.present?
      @user = User.new(:email => email, :account => @account)
      if @user.save
        
        # Send registration email
        begin
          @signup_link = "#{APP_CONFIG['base_url']}/#{params[:account_id]}/new-user/register"
          
          if ENV['RACK_ENV'] == "development"
            puts "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
            puts erb(:new_user_email, :layout => false)
          elsif (ENV['RACK_ENV'] != "test")
            send_email(settings.send_from_email, send_to_email, "You are invited to Vistazo", :new_user_email, {
              email_service_address => "smtp.sendgrid.net",
              email_service_username => ENV['SENDGRID_USERNAME'] || APP_CONFIG['email_service_username'],
              email_service_password => ENV['SENDGRID_PASSWORD'] || APP_CONFIG['email_service_password'],
              email_sevice_domain => ENV['SENDGRID_DOMAIN'] || APP_CONFIG['email_service_domain']
            })
          end
          flash[:success] = "Invitation email has been sent to #{@user.email}"
        rescue Exception => e
          puts "Email error: #{e}"
          flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time."
        end
      else
        flash[:warning] = "Email is not valid"
      end
    else
      flash[:warning] = "Account is not valid"
    end
    
    redirect '/'
  end
  
  get '/:account_id/new-user/register' do
    protected!
    
    @account = Account.find(params[:account_id])
    if @account.present?
      erb :new_user_registration
    else
      flash[:warning] = "Invalid account"
      redirect '/'
    end
  end

end