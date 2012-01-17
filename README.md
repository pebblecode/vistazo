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

To turn on/off maintenance mode on heroku

    heroku maintenance:on --app [app]
    heroku maintenance:off --app [app]

### Testing

To run all specs manually

    bundle exec rake spec

To run an individual spec

    bundle exec ruby -S rspec --color [filename]
    
    # eg,
    bundle exec ruby -S rspec --color spec/models/team_spec.rb

To run on a particular line number

    # eg, Run line 16 in spec/integration/invite_user_spec.rb
    bundle exec ruby -S rspec --color -l 16 spec/integration/invite_user_spec.rb

To run specs automatically with [guard](https://github.com/guard/guard)

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

Add remote url to local git

    git remote add sandbox git@heroku.com:vistazo-sandbox.git

To push

    git push sandbox [branch of code]:master
    
    # Or if there are conflicts, you may need to do a force push
    git push sandbox [branch of code]:master --force

## Sandbox 2

Another place for playing around with things, where you don't want to break staging or production. 
Deployed on [heroku](http://www.heroku.com/).

Project was created with (shouldn't need to be done again, but here just for reference)

    heroku create vistazo-sandbox2 --stack cedar --remote sandbox
    heroku config:add RACK_ENV=staging --app vistazo-sandbox2
    heroku addons:add mongolab:starter --app vistazo-sandbox2
    heroku addons:add sendgrid:starter --app vistazo-sandbox2
    heroku config:add LOG_LEVEL=DEBUG --app vistazo-sandbox2
    heroku config:add GOOGLE_CLIENT_ID=[google client id] --app vistazo-sandbox2
    heroku config:add GOOGLE_SECRET=[google api secret] --app vistazo-sandbox2

Google client callback url:

    http://vistazo-sandbox2.herokuapp.com/auth/google_oauth2/callback

Add remote url to local git

    git remote add sandbox2 git@heroku.com:vistazo-sandbox2.git

To push

    git push sandbox2 [branch of code]:master
    
    # Or if there are conflicts, you may need to do a force push
    git push sandbox2 [branch of code]:master --force

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

### Import/Export

#### Sandbox 2 export

    # Binary form
    mongodump -h ds029267.mongolab.com:29267 -d heroku_app2178743 -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o sandbox2-export
    
    # JSON file for a particular collection
    mongoexport -h ds029267.mongolab.com:29267 -d heroku_app2178743 -c <collection> -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o <output file>
    
    mongoexport -h ds029267.mongolab.com:29267 -d heroku_app2178743 -c users -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o vistazo-sandbox2-users.json
    mongoexport -h ds029267.mongolab.com:29267 -d heroku_app2178743 -c teams -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o vistazo-sandbox2-teams.json
    mongoexport -h ds029267.mongolab.com:29267 -d heroku_app2178743 -c team_members -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o vistazo-sandbox2-team_members.json
    mongoexport -h ds029267.mongolab.com:29267 -d heroku_app2178743 -c projects -u heroku_app2178743 -p 36ogjrk80htfg0mcvcbllqp4ji -o vistazo-sandbox2-projects.json

#### Production export

    # Binary form
    mongodump -h dbh85.mongolab.com:27857 -d heroku_app1810392 -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o vistazo-production
    
    # JSON file for a particular collection
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c <collection> -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o <output file>
    
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c users -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o vistazo-production-users.json
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c accounts -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o vistazo-production-accounts.json
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c team_members -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o vistazo-production-team_members.json
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c projects -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o vistazo-production-projects.json

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
