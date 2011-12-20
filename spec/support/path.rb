# Helper methods to navigate to paths in the application
module PathSpecHelper
  
  def homepage
    '/'
  end
  
  def google_oauth2_callback_path
    '/auth/google_oauth2/callback'
  end
  
  ############################################################################
  # Teams/users
  ############################################################################
  
  def team_path(team)
    "/#{team.id}"
  end
  
  def team_current_week_path(team)
    "/#{team.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def user_team_current_week_path(user)
    team_current_week_path(user.team)
  end
  
  def user_team_path(user)
    team_path(user.team)
  end
  
  ############################################################################
  # Projects
  ############################################################################
  
  def add_project_path(team)
    "/#{team.id}/team-member-project/add"
  end
  
  def update_project_path(team, team_member_project)
    "/#{team.id}/team-member-project/#{team_member_project.id}/update.json"
  end
  
  def update_project_with_team_id_path(team_id, team_member_project)
    "/#{team_id}/team-member-project/#{team_member_project.id}/update.json"
  end

  
end