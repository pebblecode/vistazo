# Helper functions

# encoding: utf-8
require 'sinatra/base'
require_relative 'date_helper'

module Sinatra
  module HelperMethods

    # From http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-truncate
    def truncate(text, options = {})
      options.reverse_merge!(:length => 30)
      text.truncate(options.delete(:length), options) if text
    end

    def team_id_current_week_link_url(team_id)
      "/#{team_id}/#{Time.now.year}/week/#{Date.week_num_now}"
    end

    # Works for any day in the week, but note that weeks start
    # on Sunday
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/date/rdoc/Date.html#method-i-strftime
    def week_for_day_url(team, year, month, day)
      date = Date.parse("#{year}-#{month}-#{day}")
      week = Date.week_num(date)

      week_url(team, year, week)
    end

    def week_url(team, year, week)
      "/#{team.id}/#{year}/week/#{week}"
    end
  end
  helpers HelperMethods
end