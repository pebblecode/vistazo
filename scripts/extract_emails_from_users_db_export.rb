#!/usr/bin/ruby
# extract_emails_from_users_db_export.rb
#
# Simple script to extract the emails from the users database mongo
# export
#
# To use:
#
# * Extract users from production site (see README.md)
# * Go to the `script` directory
# * Run `./extract_emails_from_users_db_export.rb`
#

users_db_export_location = "../tmp/vistazo-production-users.json"

file = File.open(users_db_export_location, "rb")
contents = file.read

# Hack way to extract name and email, using regex

# Doesn't work for when name does not exist
# Assumes name occurs before email
# name_emails = contents.scan(/("name" : "[^,]*")+.*"email" : "([^,]*)"/)
# puts "Found #{name_emails.size} users:\n\n"
# name_emails.each_with_index { |ne, index| 
# 	puts "#{ne[0]} <#{ne[1]}>#{(index != (ne.size - 1)) ? "," : ""}\n" 
# }

emails = contents.scan(/"email" : "([^,]*)"/)
puts "Found #{emails.size} user emails:\n\n"
emails.each_with_index { |e, index|
	puts "<#{e}>#{(index != (emails.size - 1)) ? "," : ""}\n" 
}




