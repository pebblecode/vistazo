#!/usr/bin/env ruby

# Migration to upgrade v0.5.1 to allow for multiple teams
# Only need to run it once.
#
# To run it:
#
#   => ruby db/migrations/2012-01-13-upgrade-0.5.1-to-multiple-teams.rb  # For development (from the project root directory)
#   => heroku run ruby db/migrations/2012-01-13-upgrade-0.5.1-to-multiple-teams.rb --app [heroku app] # For heroku server
#
# To seed old data:
#
#   For sandbox2 database (using export from mongodump):
#   => mongorestore -h ds029267.mongolab.com:29267 -d heroku_app2178743 -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji vistazo-production/heroku_app1810392
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

##############################################################################
# Team
##############################################################################

# Renamed 'accounts' to 'teams'
if (MongoMapper.database.collection_names.include? "accounts")
  MongoMapper.database.rename_collection("accounts", "teams")
  puts "Rename to 'accounts' to 'team': Done."
else
  puts "Rename to 'accounts' to 'team': 'accounts' doesn't exist. Do nothing."
end

@teams = MongoMapper.database.collection("teams")
@users = MongoMapper.database.collection("users")
@teams.find().each do |team|
  puts "Team: #{team["name"]} (_id: #{team["_id"]})"
  team_users = @users.find(:account_id => team["_id"])
  
  team["pending_users"] ||= []
  team["active_users"] ||= []
  
  team_users.find().each do |user|
    # Add active/pending users (adapted from: https://github.com/pebblecode/vistazo/blob/a095fe9c41418a810ee3dfd4edb02d83d36088bd/models/user.rb)
    if (user["uid"] == nil) and (user["email"] != nil)     # Missing email
      team["pending_users"] << user_to_hash(user)
      puts "\tAdded '#{user["email"]}' hash to pending_users of '#{team["name"]}' team"
    elsif (user["uid"] != nil) and (user["email"] != nil)  # Email and uid present
      team["active_users"] << user_to_hash(user)
      puts "\tAdded '#{user["email"]}' hash to active_users of '#{team["name"]}' team"
    end
    
    # Add team to user team_ids
    user["team_ids"] ||= []
    user["team_ids"] << team["_id"]
    
    @users.update({"_id" => user["_id"]}, user)
    puts "\tDONE: updated user #{user}"
  end
  
  # Update db
  @teams.update({"_id" => team["_id"]}, team)
  puts "\tDONE: Added pending_users: #{team["pending_users"]}"
  puts "\tDONE: Added active_users: #{team["active_users"]}"
end

##############################################################################
# TeamMember.team_member_projects changed to TeamMember.timetable_items
# But not explicitly defined anywhere, so nothing to do
##############################################################################

##############################################################################
# User
##############################################################################

@users = MongoMapper.database.collection("users")
@users.find().each do |user|
  user.delete("account_id")
  @users.update({"_id" => user["_id"]}, user)
  puts "DONE: Removed account_id from user '#{user["email"]}'"
end
