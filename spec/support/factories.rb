require 'factory_girl'

Factory.define :team do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
end

Factory.define :user do |f|
  f.sequence(:name) { |n| "User #{n}" }
  f.sequence(:email) { |n| "user_#{n}@example.com" }
  # No teams by default
end

Factory.define :project do |f|
  f.sequence(:name) { |n| "Project #{n}" }
  f.association :team
end

Factory.define :user_timetable do |f|
  f.association :user
end

Factory.define :timetable_item do |f|
  f.date Time.now 
  f.association :project
  f.association :user_timetable
end