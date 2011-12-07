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
          send_registration_email_to @user.email
          flash[:success] = "Invitation email has been sent to #{@user.email}"
        rescue Exception => e
          puts "Email error: #{e}"
          flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{e}"
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
  
  get '/:account_id/new-user/:user_id/resend' do
    protected!
  
    @account = Account.find(params[:account_id])
    if @account.present?
      begin
        @user = User.find(params[:user_id])
        if @user.present?
          send_registration_email_to @user.email
          flash[:success] = "Invitation email has been resent to #{@user.email}"
        else
          flash[:warning] = "Invalid user to resend email to."
        end
      rescue Exception => e
        puts "Email error: #{e}"
        flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{e}"
      end
    else
      flash[:warning] = "Invalid account"
    end
    
    redirect back
  end
  
  private
  
  
  def send_registration_email_to(send_to_email)
    @signup_link = "#{APP_CONFIG['base_url']}/#{params[:account_id]}/new-user/register"
    
    send_from_email = settings.send_from_email
    subject = "You are invited to Vistazo"
    
    email_params = {
      :email_service_address => "smtp.sendgrid.net",
      :email_service_username => ENV['SENDGRID_USERNAME'] || APP_CONFIG['email_service_username'],
      :email_service_password => ENV['SENDGRID_PASSWORD'] || APP_CONFIG['email_service_password'],
      :email_sevice_domain => ENV['SENDGRID_DOMAIN'] || APP_CONFIG['email_service_domain']
    }
    
    if ENV['RACK_ENV'] == "development"
      puts "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
      puts "send_from_email: #{send_from_email}"
      puts "send_to_email: #{send_to_email}"
      puts "params: #{email_params}"
      puts "subject: #{subject}"
              
      puts erb(:new_user_email, :layout => false)
    elsif (ENV['RACK_ENV'] != "test")
      if ENV['RACK_ENV'] == "staging"
        puts "STAGING MODE: this email should be sent:"
        puts "send_from_email: #{send_from_email}"
        puts "send_to_email: #{send_to_email}"
        puts "params: #{email_params}"
        puts "subject: #{subject}"
        
        puts erb(:new_user_email, :layout => false)
      end
    
      puts erb(:new_user_email, :layout => false)
      
      send_email(send_from_email, send_to_email, subject, :new_user_email, email_params)
    end
  end

end