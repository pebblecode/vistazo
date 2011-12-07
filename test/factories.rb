require 'factory_girl'

Factory.define :account do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
end

Factory.define :user do |f|
  f.sequence(:name) { |n| "User #{n}" }
  f.sequence(:email) { |n| "user_#{n}@example.com" }
end
