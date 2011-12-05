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

  get '/:account_id/invite-user' do
    logger.log params
    "Invite user for #{account_id}"
  end

end