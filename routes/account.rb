class VistazoApp < Sinatra::Application

  get '/:account' do
    protected!
  
    @account = Account.find_by_url_slug(params[:account])
  
    if @account.present?
      redirect "/#{params[:account]}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
    else
      flash.next[:warning] = "Invalid account."
      redirect '/'
    end
  end

end