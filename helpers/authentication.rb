# encoding: utf-8
require 'sinatra/base'
require 'sinatra/flash'
module Sinatra
  module  BasicAuthentication
    def current_user
      @current_user ||= User.find_by_uid(session['uid'])
    end
    def current_user?
      current_user ? true : false
    end
    def log_out
      session["uid"] = nil
      redirect "/"
    end
    def logged_in?
      current_user?
    end

    def require_user!
      unless current_user?
        flash[:warning] = "You must be logged in"
        redirect "/"
      end
    end
    def require_account_user!(account_id)
      require_user!
      account = Account.find(account_id)
      unless current_user.account == account
        flash[:warning] = "You're not authorized to view this page."
        redirect "/"
      end
    end
  end
  helpers BasicAuthentication
end
