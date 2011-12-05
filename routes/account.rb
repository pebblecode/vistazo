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
        flash[:success] = "Invitation email has been sent to #{@user.email}"
      
        # TODO
      else
        flash[:warning] = "Email is not valid"
      end
    else
      flash[:warning] = "Account is not valid"
    end
    
    redirect '/'
  end

end