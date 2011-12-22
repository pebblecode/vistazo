# Helper methods to navigate to paths in the application
module PathSpecHelper
  
  def homepage
    '/'
  end
  
  def google_oauth2_callback_path
    '/auth/google_oauth2/callback'
  end
  
  def logout_path
    '/logout'
  end
  
  ############################################################################
  # Teams/users
  ############################################################################
  
  def team_id_path(team_id)
    "/#{team_id}"
  end
  
  def team_path(team)
    team_id_path(team.id)
  end
  
  def team_current_week_path(team)
    "/#{team.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def team_id_current_week_path(team_id)
    "/#{team_id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def user_team_current_week_path(user)
    team_current_week_path(user.teams.first)
  end
  
  def user_team_path(user)
    team_path(user.teams.first)
  end
  
  ############################################################################
  # Projects
  ############################################################################
  
  def add_project_path(team)
    "/#{team.id}/team-member-project/add"
  end
  
  def update_project_path(team, timetable_item)
    "/#{team.id}/team-member-project/#{timetable_item.id}/update.json"
  end
  
  def update_project_with_team_id_path(team_id, timetable_item)
    "/#{team_id}/team-member-project/#{timetable_item.id}/update.json"
  end

  
end