# Helper functions

# encoding: utf-8
require 'sinatra/base'

module Sinatra
  module HelperMethods
    # From http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-truncate
    def truncate(text, options = {})
      options.reverse_merge!(:length => 30)
      text.truncate(options.delete(:length), options) if text
    end
    
    def is_today?(date)
      (date.year == Time.now.year) and (date.month == Time.now.month) and (date.day == Time.now.day)
    end

    def team_id_current_week_link_url(team_id)
      "/#{team_id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
    end
  end
  helpers HelperMethods
end