#!/usr/bin/env ruby

# Migration to remove any user team_ids for which the user is pending (see https://github.com/pebblecode/vistazo/issues/151)
# Only need to run it once.
#
# To run it:
#
#   => ruby db/migrations/2012-01-17-remove-pending-teams-from-user-team_ids.rb  # For development (from the project root directory)
#   => heroku run ruby db/migrations/2012-01-17-remove-pending-teams-from-user-team_ids.rb --app [heroku app] # For heroku server
#

require 'mongo_mapper'
require_relative "../../lib/mongo_helper"

# For testing
ENV["RACK_ENV"] ||= "development"
db_url = if ENV["RACK_ENV"] == "development"
    'mongomapper://localhost:27017/vistazo-development'
  elsif ENV["RACK_ENV"] == "production" or ENV["RACK_ENV"] == "staging"
    # For heroku
    ENV['MONGOLAB_URI']
  else
    puts "Unknown RACK_ENV: '#{ENV["RACK_ENV"]}'"
    exit
  end
puts "Connecting to #{db_url}"
setup_mongo_connection(db_url)

# Adapted from User.to_hash (https://github.com/pebblecode/vistazo/blob/3a69818d2038cb1508910a3de85e59275b5172e2/models/user.rb)
def user_to_hash(user)
  { "id" => user["_id"].to_s, "uid" => user["uid"], "name" => user["name"], "email" => user["email"] }
end

@teams = MongoMapper.database.collection("teams")
@users = MongoMapper.database.collection("users")
@users.find().each do |user|
  user["team_ids"].each do |team_id|
    team = @teams.find_one(team_id)
    
    if (team["pending_users"].include? user_to_hash(user))
      user["team_ids"].delete(team_id)
      puts "Deleted team (#{team_id}) from user (#{user["_id"]})"
    end
  end
  
  @users.update({"_id" => user["_id"]}, user)
  puts "DONE: Updated team_ids for user '#{user["email"]}'"
end