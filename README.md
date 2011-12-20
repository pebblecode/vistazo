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

To ensure the Google OAuth callback is correct ensure you run the site from http://localhost:6100

### Testing

To run tests manually

    bundle exec rake spec

To run tests automatically with [guard](https://github.com/guard/guard)

    bundle exec guard

### UX testing

For UX testing, there is a [ux-sandbox-testing](http://github.com/pebblecode/vistazo/tree/ux-sandbox-testing) branch that allows for modifications to be made to the code that can be deployed specifically for ux testing. Currently, we are deploying to http://vistazo-sandbox.herokuapp.com.

To push code to the sandbox, checkout the branch and run:

    git push sandbox ux-sandbox-testing:master


## Sandbox

For playing around with things, where you don't want to break staging or production. 
Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo-sandbox --stack cedar --remote sandbox
    heroku config:add RACK_ENV=staging --app vistazo-sandbox
    heroku addons:add mongolab:starter --app vistazo-sandbox
    heroku addons:add sendgrid:starter --app vistazo-sandbox
    heroku config:add LOG_LEVEL=DEBUG --app vistazo-sandbox
    heroku config:add GOOGLE_CLIENT_ID=[google client id] --app vistazo-sandbox
    heroku config:add GOOGLE_SECRET=[google api secret] --app vistazo-sandbox

Google client callback url:

    http://vistazo-sandbox.herokuapp.com/auth/google_oauth2/callback

To push

    git push sandbox [branch of code]:master
    
    # Or if there are conflicts, you may need to do a force push
    git push sandbox [branch of code]:master --force

## Staging

Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo-staging --stack cedar --remote staging
    heroku config:add RACK_ENV=staging --app vistazo-staging
    heroku addons:add mongolab:starter --app vistazo-staging
    heroku addons:add sendgrid:starter --app vistazo-staging
    heroku config:add LOG_LEVEL=DEBUG --app vistazo-staging
    heroku config:add GOOGLE_CLIENT_ID=[google client id] --app vistazo
    heroku config:add GOOGLE_SECRET=[google api secret] --app vistazo

To find the google api client id/secret go to [google api console](https://code.google.com/apis/console/b/0/#project:565404561857:access)

Google client callback url:

    http://vistazo-staging.herokuapp.com/auth/google_oauth2/callback

Staging uses [MongoLab](http://devcenter.heroku.com/articles/mongolab).

Initial setup

    git checkout --track -b staging origin/staging

Merging code and pushing to staging branch

    git checkout staging; git merge master
    git push origin staging:staging

    # Or as a rake task
    rake merge_push_to:staging


To push to the staging server

    git push staging staging:master

    # Or as a rake task
    rake deploy:staging

    # Or as a merge, push and deploy rake task
    rake shipit:staging

This is deployed at: http://vistazo-staging.herokuapp.com/


## Production

Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo --stack cedar --remote production
    heroku config:add RACK_ENV=production --app vistazo
    heroku addons:add mongolab:starter --app vistazo
    heroku addons:add sendgrid:starter --app vistazo
    heroku config:add LOG_LEVEL=DEBUG --app vistazo
    heroku config:add GOOGLE_CLIENT_ID=[google client id] --app vistazo
    heroku config:add GOOGLE_SECRET=[google api secret] --app vistazo
    
    heroku addons:add custom_domains --app vistazo
    heroku domains:add www.vistazoapp.com --app vistazo
    heroku domains:add vistazoapp.com --app vistazo
    
    # For redirects (http://github.com/cwninja/rack-force_domain)
    heroku config:add DOMAIN="vistazoapp.com" --app vistazo
    
To find the google api client id/secret go to [google api console](https://code.google.com/apis/console/b/0/#project:139948808699:access)

Google client callback url:

    http://vistazo.herokuapp.com/auth/google_oauth2/callback
    
Production uses [MongoLab](http://devcenter.heroku.com/articles/mongolab).

Initial setup

    git checkout --track -b production origin/production

Merging code and pushing to production branch

    git checkout production; git merge master
    git push origin production:production
    
    # Or as a rake task
    rake merge_push_to:production
    

To push to the production server

    git push production production:master
    
    # Or as a rake task
    rake deploy:production
    
    # Or as a merge, push and deploy rake task
    rake shipit:production
    
This is deployed at: http://vistazo.herokuapp.com/

## Mongo

### Add new team member

To an a new team member in the mongo backend interface on staging or production:

1. Log into heroku
1. My apps > `vistazo` or `vistazo-staging` > Add-ons > Mongo Lab > team_members > 
Add > Copy the following code (making sure oid is unique):

    ```
    { "_id" : {"$oid": "4ecf82c6b01a520547000011"},
      "name" : "Satish S",
      "timetable_items" : [] }
    ```
1. Click on create

### Searches

Pending users

    {
        "uid": {
            "$exists": false
        },
        "email": {
            "$exists": true
        }
    }
