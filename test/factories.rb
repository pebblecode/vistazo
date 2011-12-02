require 'factory_girl'

Factory.define :account do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
end
