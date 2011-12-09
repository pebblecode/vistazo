# Helper methods to navigate to paths in the application
module PathSpecHelper
  
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
  
end