class VistazoApp < Sinatra::Application
  post '/reset' do
    protected!
  
    # Delete everything
    TeamMember.delete_all()
    Project.delete_all()
    ColourSetting.delete_all()
    Account.delete_all()
    User.delete_all()
  
    flash[:success] = "Successfully cleared out the database and added seed data. Enjoy!"
    redirect '/'
  end
end