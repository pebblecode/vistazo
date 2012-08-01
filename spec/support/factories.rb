require 'factory_girl'

Factory.define :team do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
end

Factory.define :user do |f|
  f.sequence(:name) { |n| "User #{n}" }
  # email `n` seems to be off by 1
  f.sequence(:email) { |n| "user_#{n - 1}@example.com" }
  # No teams by default
end

Factory.define :project do |f|
  f.sequence(:name) { |n| "Project #{n}" }
  f.association :team
end

Factory.define :user_timetable do |f|
  f.association :user
  f.association :team
end

Factory.define :timetable_item do |f|
  f.date Time.now
  f.association :project
  f.association :user_timetable

  # To construct manually, you will want to pass it an
  # user_timetable, as user and team are generated on creation.
  # So, :user and :team should not be created when creating :timetable_item
  # f.association :user
  # f.association :team
end