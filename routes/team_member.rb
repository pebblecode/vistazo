class VistazoApp < Sinatra::Application
  post '/:account/team-member/add' do
    protected!
  
    account = Account.find_by_url_slug(params[:account])
  
    puts "Add team member: #{params}"
  
    if account.present?
      team_member_name = params[:new_team_member_name]
    
      if team_member_name.present?
        team_member = TeamMember.create(:name => team_member_name, :account_id => account.id)
      
        flash[:success] = "Successfully added '<em>#{team_member.name}</em>'."
      else
        flash[:warning] = "Please specify a team member name."
      end
      
    else
      flash[:warning] = "Invalid account"
    end
  
    redirect back
  end
end