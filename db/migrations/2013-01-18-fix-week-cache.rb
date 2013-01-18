#!/usr/bin/env ruby

# Migration to fix week cache. See (see https://github.com/pebblecode/vistazo/issues/252).
# Only need to run it once.
#
# To run it:
#
#   => ruby db/migrations/2013-01-18-fix-week-cache.rb  # For development (from the project root directory)
#   => heroku run ruby db/migrations/2013-01-18-fix-week-cache.rb --app [heroku app] # For heroku server
#

require_relative "../../web"

@timetable_items_col = MongoMapper.database.collection("timetable_items")
@timetable_items_col.find().each do |ti|
  # Resave to update cache
  newTI = TimetableItem.create(ti)
  newTI.save(:safe => true)
  puts "Updated timetable item: #{newTI.to_json}"
end

puts "DONE: Updated cache of all timetable items"