# encoding: utf-8
require 'sinatra/base'
require 'sinatra/flash'
module Sinatra
  module  BasicAuthentication
    def current_user
      unless session['uid'].nil?
        # NOTE: Do not allow nil through, as it'll find users with user.uid == nil
        @current_user ||= User.find_by_uid(session['uid'])
      end
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
        flash[:warning] = "You must be logged in."
        redirect "/"
      end
    end
    def require_team_user!(team_id)
      require_user!
      team = Team.find(team_id)
      unless current_user.team == team
        flash[:warning] = "You're not authorized to view this page."
        redirect "/"
      end
    end
    
    def is_super_admin?
      if current_user
        if current_user.email == "ttt@pebblecode.com"
          return true
        end
      end
      return false
    end
  end
  helpers BasicAuthentication
end
