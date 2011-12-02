class VistazoApp < Sinatra::Application
  get '/auth/:provider/callback' do
    hash = request.env['omniauth.auth'].to_hash
    @user = User.find_by_uid(hash["uid"])
    unless @user.present?
      @user = User.create(
        :uid   => hash["uid"],
        :name  => hash["info"]["name"],
        :email => hash["info"]["email"]
      )
      unless @user.valid?
        flash[:warning] = "Could not retrieve user."
        @user = nil
        redirect '/'
      end
    end
    
    @account = @user.account
    unless @account
      @account = create_account
      
      # Add the user as the first team member
      @account.team_members << TeamMember.create(:name => @user.name)
      
      flash[:success] = "Welcome to Vistazo! We're ready for you to add projects for yourself."
    end
    
    session['uid'] = @user.uid
    redirect '/'
  end

  get '/auth/failure' do
    flash[:warning] = "To access vistazo, you need to login with your Google account."
    redirect "/"
  end
  get '/logout' do
    flash[:success] = "Logged out successfully"
    log_out
  end


  private
  
  def create_account
    @user.account = Account.create(:name => "#{@user.name}'s schedule")
    @user.save
    return @user.account
  end
end