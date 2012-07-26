#!/usr/bin/env ruby

# Migration to make user timetables and timetable item
# a document instead of an embedded document (see https://github.com/pebblecode/vistazo/issues/248)
# Only need to run it once.
#
# Note: Models need to be in a certain state [TODO: Add commit where models changed]
#
# To run it:
#
#   => ruby db/migrations/2012-07-26-timetable-item-refactor.rb  # For development (from the project root directory)
#   => heroku run ruby db/migrations/2012-07-26-timetable-item-refactor.rb --app [heroku app] # For heroku server
#

require_relative "../../web"

# @teams = MongoMapper.database.collection("teams").find()
@teams_col = MongoMapper.database.collection("teams")
@teams_col.find().each do |team|
  # Create new user_timetables
  user_timetables = team["user_timetables"]

  puts "Looking at team: #{team["name"]}"
  unless user_timetables.nil?
    user_timetables.each do |ut|
      # Create timetable item
      timetable_items = ut["timetable_items"]

      unless timetable_items.nil?
        timetable_items.each do |ti| 
          newTI = TimetableItem.create(ti)
          newTI["user_timetable_id"] = ut["_id"]
          newTI.save(:safe => true)
          puts "\tCreated timetable item: #{newTI.to_json}"
        end

        ut.delete("timetable_items")
        newUT = UserTimetable.create(ut)
        puts "\tCreated user timetable: #{newUT.to_json}\n\n"
      end
    end
  end

  # Delete user_timetables from team
  team.delete("user_timetables")

  # Update team
  @teams_col.update({"_id" => team["_id"]}, team)
  puts "DONE: Updated team '#{team["name"]}' (_id: #{team["_id"]})"
end