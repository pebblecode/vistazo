# encoding: utf-8
require 'sinatra/base'

module Sinatra
  module  BasicAuthentication
    def current_user
      @current_user ||= User.find_by_uid(session['uid'])
    end
    def current_user?
      current_user ? true : false
    end
    def log_out
      @current_user = nil
    end
    def logged_in?
      current_user?
    end
  end
  helpers BasicAuthentication
end
