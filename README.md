# Vistazo

A light weight application to keep track of who's working on what, when.

## Installation

1. [Install mongodb](http://www.mongodb.org/display/DOCS/Quickstart+OS+X)

## Development

To set up

    gem install bundler
    bundle install

To run

    foreman start dev -p 6000
    # open http://localhost:6100/
    
## Production

Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create --stack cedar
    heroku rename vistazo
    heroku config:add RACK_ENV=production
    heroku addons:add mongolab:starter          # Uses [MongoLab](http://devcenter.heroku.com/articles/mongolab)

To deploy

    git push heroku master

This is deployed at: http://vistazo.herokuapp.com/