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
  # Teams
  ############################################################################
  
  def team_id_path(team_id)
    "/#{team_id}"
  end
  
  def team_path(team)
    team_id_path(team.id)
  end
  
  def team_week_path(team, year, week)
    "/#{team.id}/#{year}/week/#{week}"
  end

  def team_id_month_path(team_id, year, month)
    "/#{team_id}/#{year}/month/#{month}"
  end

  def team_month_path(team, year, month)
    team_id_month_path(team.id, year, month)
  end

  def team_current_week_path(team)
    "/#{team.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def team_id_current_week_path(team_id)
    "/#{team_id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  ############################################################################
  # Teams/users
  ############################################################################

  def user_team_current_week_path(user)
    team_current_week_path(user.teams.first)
  end
  
  def user_team_path(user)
    team_path(user.teams.first)
  end

  def team_add_user(team)
    "/#{team.id}/user-timetables/new-user.json"
  end
  
  def team_update_user(team, user)
    "/#{team.id}/users/#{user.id}"
  end

  def team_delete_user(team, user)
    "/#{team.id}/users/#{user.id}/delete"
  end

  
  ############################################################################
  # Timetable items
  ############################################################################

  def add_timetable_item_path(team, user)
    "/#{team.id}/users/#{user.id}/timetable-items/new.json"
  end
  
  def update_timetable_item_path(team, timetable_item)
    "/#{team.id}/timetable-items/#{timetable_item.id}/update.json"
  end

  def delete_timetable_item_path(team, user, timetable_item)
    "/#{team.id}/users/#{user.id}/timetable-items/#{timetable_item.id}/delete.json"
  end


  ############################################################################
  # Projects
  ############################################################################
  
  def delete_project_path(team, project)
    delete_project_path_with_project_id(team, project.id)
  end
  
  def delete_project_path_with_project_id(team, project_id)
    "/#{team.id}/project/#{project_id}/delete"
  end
  
end