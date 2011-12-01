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
    get_account || create_account
    session['uid'] = @user.uid
    redirect '/'
  end

  get '/auth/failure' do
    flash[:warning] = "To access vistazo, you need to login with your google account."
    redirect "/"
  end
  get '/logout' do
    flash[:success] = "Logged out successfully"
    log_out
  end

  def get_account
    @account = @user.account
  end
  def create_account
    @user.account = Account.create(:name => "#{@user.name}'s schedule")
    @user.save
    return @user.account
  end
end