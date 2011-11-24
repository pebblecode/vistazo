# Vistazo

A light weight application to keep track of who's working on what, when.


## Installation

1. [Install mongodb](http://www.mongodb.org/display/DOCS/Quickstart+OS+X)
1. Install [MongoHub](http://mongohub.todayclose.com/) if you'd like a GUI interface
1. Add your heroku account to the `vistazo` and `vistazo-staging` projects (through the `dev@pebblecode.com` account) and set up the staging/production git deployment environments:

    ```
    git remote add staging git@heroku.com:vistazo-staging.git
    git remote add production git@heroku.com:vistazo.git
    ```

## Development

To set up

    gem install bundler
    bundle install

To run

    foreman start dev
    # open http://localhost:6100/


## Staging

Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo-staging --stack cedar --remote staging
    heroku config:add RACK_ENV=staging --app vistazo-staging
    heroku addons:add mongolab:starter --app vistazo-staging

Staging uses [MongoLab](http://devcenter.heroku.com/articles/mongolab).

To deploy the staging branch:

1. Check out the staging branch

    git checkout --track -b staging origin/staging

1. Push to the staging server

    git push staging staging:master

This is deployed at: http://vistazo-staging.herokuapp.com/


## Production

Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo --stack cedar --remote production
    heroku config:add RACK_ENV=production --app vistazo
    heroku addons:add mongolab:starter --app vistazo
    
Production uses [MongoLab](http://devcenter.heroku.com/articles/mongolab).

To deploy the production branch:

1. Check out the staging branch

    git checkout --track -b production origin/production

1. Push to the staging server

    git push production production:master

This is deployed at: http://vistazo.herokuapp.com/