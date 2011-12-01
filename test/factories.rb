require 'factory_girl'

Factory.define :account do |f|
  f.sequence(:name) { |n| "Software shop #{n}" }
  f.sequence(:url_slug) { |n| "software-shop-#{n}" }
end
