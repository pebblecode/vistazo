# Helper methods to navigate to paths in the application
module PathSpecHelper
  
  def homepage
    '/'
  end
  
  def google_oauth2_callback_path
    '/auth/google_oauth2/callback'
  end
  
  ############################################################################
  # Accounts/users
  ############################################################################
  
  def account_path(account)
    "/#{account.id}"
  end
  
  def account_current_week_path(account)
    "/#{account.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def user_account_current_week_path(user)
    account_current_week_path(user.account)
  end
  
  def user_account_path(user)
    account_path(user.account)
  end
  
  ############################################################################
  # Projects
  ############################################################################
  
  def add_project_path(account)
    "/#{account.id}/team-member-project/add"
  end
  
  def update_project_path(account, team_member_project)
    "/#{account.id}/team-member-project/#{team_member_project.id}/update.json"
  end
  
end