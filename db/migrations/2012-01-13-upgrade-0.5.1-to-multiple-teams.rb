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


##############################################################################
# Team
##############################################################################

# Renamed from accounts collection
if (MongoMapper.database.collection_names.include? "accounts")
  MongoMapper.database.rename_collection("accounts", "teams")
end

# Add active_users
print MongoMapper.database.collection("teams")
MongoMapper.database.collection("teams").each do |team|
  user = MongoMapper.database.collection("users").find(:account_id => team.id)
  
  print user
  # Find active users
  
  # Add active users
  # team.active_users
  
  # Find pending users
  
  # Add pending users
  
  # team.save
end

# Change TeamMember.team_member_projects to TeamMember.timetable_items - not explicitly defined?

# User
# + team_ids from User.account_id
# - account_id

# db.collection.update( criteria, objNew, upsert, multi )
