class VistazoApp < Sinatra::Application

  get '/accounts' do
    @accounts = Account.all
    
    flash[:warning] = "Note: This place is temporary. For privileged access only!"
    erb :accounts
  end

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

end