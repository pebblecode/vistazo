# Handles all project and team member project functionality
class VistazoApp < Sinatra::Application
  post '/:account/team-member-project/add' do
    protected!

    account = Account.find_by_url_slug(params[:account])
    team_member = TeamMember.find(params[:team_member_id])
    date = Date.parse(params[:date])
  
    puts "Add team member project: #{params}"
  
    if params[:new_project].present?
      project_name = params[:new_project_name]
    
      if project_name.present?
        if account.present?
          project = Project.create(:name => project_name, :account_id => account.id)
          team_member.add_project_on_date(project, date)
      
          flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
        else
          flash[:warning] = "Invalid account."
        end
      else
        flash[:warning] = "Please specify a project name."
      end
    else
      project = Project.find(params[:project_id])
      if (team_member.present? and project.present? and date.present?)
        team_member.add_project_on_date(project, date)
      
        flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
      else
        flash[:warning] = "Something went wrong when adding a team member project. Please refresh and try again later."
      end
    end
  
    redirect back
  end

  post '/team-member-project/:tm_project_id/update.json' do
    protected!

    from_team_member = TeamMember.find(params[:from_team_member_id])
    to_team_member = TeamMember.find(params[:to_team_member_id])
    team_member_project = from_team_member.team_member_projects.find(params[:tm_project_id]) if from_team_member
    to_date = Date.parse(params[:to_date])
  
    puts "Update team member project params: #{params}"
  
    output = ""
    if (from_team_member.present? and to_team_member.present? and team_member_project.present? and to_date.present?)
      successful_move = from_team_member.move_project(team_member_project, to_team_member, to_date)
    
      if successful_move
        status 200
        output = { :message => "Successfully moved '<em>#{team_member_project.project_name}</em>' project to #{to_team_member.name} on #{to_date}." }
      else
        status 500
        output = { :message => "Something went wrong with saving the changes when updating team member project. Please refresh and try again later." }
      end
    else
      status 400
      output = { :message => "Something went wrong with the input when updating team member project. Please refresh and try again later." }
    end

    content_type :json 
    output.to_json
  end

  post '/team-member/:team_member_id/project/:tm_project_id/delete' do
    protected!
  
    team_member = TeamMember.find(params[:team_member_id])
  
    if team_member.present?
      did_delete = team_member.team_member_projects.reject! { |proj| proj.id.to_s == params[:tm_project_id] }
      team_member.save

      if did_delete
        flash[:success] = "Successfully deleted team member project for #{team_member.name}."
      else
        flash[:warning] = "Something went wrong when trying to delete a team member project for #{team_member.name}. Please try again later."
      end
    else
      flash[:warning] = "Something went wrong when trying to delete a team member project. Please refresh and try again later."
    end
  
    redirect back
  end
end