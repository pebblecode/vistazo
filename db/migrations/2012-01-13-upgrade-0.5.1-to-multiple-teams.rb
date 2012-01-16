# Migration to upgrade v0.5.1 to allow for multiple teams
# Only need to run it once.
#
# To run it (from the project root directory):
#
#     ruby db/migrations/2012-01-13-upgrade-0.5.1-to-multiple-teams.rb
#
require 'mongo_mapper'
require_relative "../../lib/mongo_helper"


# For testing
setup_mongo_connection('mongomapper://localhost:27017/vistazo-development')
# For heroku
# setup_mongo_connection(ENV['MONGOLAB_URI'])

# Adapted from User.to_hash (https://github.com/pebblecode/vistazo/blob/3a69818d2038cb1508910a3de85e59275b5172e2/models/user.rb)
def user_to_hash(user)
  { "id" => user["_id"].to_s, "uid" => user["uid"], "name" => user["name"], "email" => user["email"] }
end

##############################################################################
# Team
##############################################################################

# Renamed from accounts collection
if (MongoMapper.database.collection_names.include? "accounts")
  MongoMapper.database.rename_collection("accounts", "teams")
  puts "Rename to 'accounts' to 'team': Done."
else
  puts "Rename to 'accounts' to 'team': 'accounts' doesn't exist. Do nothing."
end

@teams = MongoMapper.database.collection("teams")
@teams.find().each do |team|
  puts "Team: #{team["name"]} (_id: #{team["_id"]})"
  @users = MongoMapper.database.collection("users").find(:account_id => team["_id"])
  
  team["pending_users"] = []
  team["active_users"] = []
  
  # Add active_users
  @users.find().each do |user|
    # Adapted from: https://github.com/pebblecode/vistazo/blob/a095fe9c41418a810ee3dfd4edb02d83d36088bd/models/user.rb
    if (user["uid"] == nil) and (user["email"] != nil)     # Missing email
      team["pending_users"] << user_to_hash(user)
      puts "\tAdded '#{user["email"]}' hash to pending_users of '#{team["name"]}' team"
    elsif (user["uid"] != nil) and (user["email"] != nil)  # Email and uid present
      team["active_users"] << user_to_hash(user)
      puts "\tAdded '#{user["email"]}' hash to active_users of '#{team["name"]}' team"
    end
  end
  
  # Update db
  # @teams.update({"_id" => BSON::ObjectId(team["_id"])}, team)
  @teams.update({"_id" => team["_id"]}, team)
  puts "\tDONE: Added pending_users: #{team["pending_users"]}"
  puts "\tDONE: Added active_users: #{team["active_users"]}"
end

# Change TeamMember.team_member_projects to TeamMember.timetable_items - not explicitly defined?

# User
# + team_ids from User.account_id
# - account_id

# db.collection.update( criteria, objNew, upsert, multi )
