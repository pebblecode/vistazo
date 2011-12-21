require 'factory_girl'

Factory.define :team do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
end

Factory.define :user do |f|
  f.sequence(:name) { |n| "User #{n}" }
  f.sequence(:email) { |n| "user_#{n}@example.com" }
  # No teams by default
end

Factory.define :team_member do |f|
  f.sequence(:name) { |n| "User #{n}" }
  f.association :team
end

