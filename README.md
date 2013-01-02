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

### Data migrations

Currently all migrations are manually run. We will look into automated migrations in #160.

The easiest approach for fixing data migration issues is to reset the database:

    mongo vistazo-development
    > db.dropDatabase()

However, for reference, here is a listing of migrations that can be run (from the root directory):

    ruby db/migrations/2012-01-13-upgrade-0.5.1-to-multiple-teams.rb
    ruby db/migrations/2012-01-17-remove-pending-teams-from-user-team_ids.rb


## Development

To set up

    gem install bundler
    bundle install

To run (using the development procfile)

    bundle exec rake server
    # open http://localhost:6100/

To ensure the Google OAuth callback is correct ensure you run the site from http://localhost:6100

To turn on/off maintenance mode on heroku

    heroku maintenance:on --app [app]
    heroku maintenance:off --app [app]

### Mongo db

To get access to the mongo development database:

    mongo vistazo-development

### Testing

To run all specs manually

    bundle exec rake spec

To run an individual spec

    bundle exec rake spec:run[filename]

    # eg,
    bundle exec rake spec:run[spec/models/team_spec.rb]

To run on a particular line number

    # eg, Run line 16 in spec/integration/invite_user_spec.rb
    bundle exec rake spec:run[spec/integration/invite_user_spec.rb,16]

    # Note: there are no spaces between the commas

To run specs automatically with [guard](https://github.com/guard/guard)

    bundle exec guard

#### Javascript testing

Using [jasmine](https://github.com/pivotal/jasmine-gem).

To install (after adding `jasmine` gem in `Gemfile`):

    bundle exec jasmine init

To start jasmine server:

    rake jasmine

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
    heroku addons:add mongolab:small --app vistazo # See [this](https://devcenter.heroku.com/articles/mongolab#upgrading_to_a_larger_mongolab_plan) for how to do upgrades
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

### Usage statitics

    rake db:stats:production

## Google oauth

To use Google oauth, a client id and client secret needs to be generated in the [Google APIs console](https://code.google.com/apis/console).

The following are links to the respective API consoles:

* [Vistazo development](https://code.google.com/apis/console/b/0/?pli=1#project:431161751732:access)
* [Vistazo staging](https://code.google.com/apis/console/b/0/?pli=1#project:565404561857:access)
* [Vistazo sandbox](https://code.google.com/apis/console/b/0/?pli=1#project:780676367024:access)
* [Vistazo production](https://code.google.com/apis/console/b/0/?pli=1#project:139948808699:access)

Vistazo development client id and secret are stored in `config/config.yml`, while the rest are stored in `ENV` variables (see respective sections in the readme so see how)

### For virtual machines

Add the following to `c:\windows\system32\drivers\etc\hosts` (for windows xp, or find equivalent on different versions of windows)

    10.0.2.2    vistazodevelopment.com

`vistazodevelopment.com` is setup as an arbitrary url for development. I couldn't use `10.0.2.2` or `something.local` or anything similar for some reason.


## Mongo

### Reset database

Development

    rake db:reset:dev   # or rake db:reset:development

Staging

    rake db:reset:staging

Production

    # Uncomment rake task first (done to prevent stupidity)
    rake db:reset:production


### Import/Export

#### Development import

Drop db first

    mongo vistazo-development
    > db.dropDatabase()

Import files, eg:

    mongoimport -d vistazo-development -c teams tmp/vistazo-production-teams.json
    mongoimport -d vistazo-development -c users tmp/vistazo-production-users.json
    mongoimport -d vistazo-development -c team_members tmp/vistazo-production-team_members.json
    mongoimport -d vistazo-development -c colour_settings tmp/vistazo-production-colour_settings.json
    mongoimport -d vistazo-development -c projects tmp/vistazo-production-projects.json

To import from `mongodump` export

    mongorestore -h dbh85.mongolab.com:27857 -d heroku_app1810392 -u heroku_app1810392 -p <password> <folder>/*

#### Production export

There is a rake task that backs up production into the tmp/backups directory. To run it:

    rake db:backup:production

Or to back up production manually:

    # Binary form
    mongodump -h ds031827.mongolab.com:31827 -d heroku_app1810392 -u heroku_app1810392 -p <password> -o vistazo-production

    # JSON file for a particular collection
    mongoexport -h dbh85.mongolab.com:27857 -d heroku_app1810392 -c <collection> -u heroku_app1810392 -p cvrq46aj94ck3ltmbq14cm1bd4 -o <output file>


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

## Troubleshooting

## Problems with starting the server

eg,

    16:19:46 web.1     | /Users/markdurrant/.rbenv/versions/1.9.2-p290/lib/ruby/gems/1.9.1/gems/eventmachine-0.12.10/lib/eventmachine.rb:572:in `start_tcp_server': no acceptor (RuntimeError)

or

    Errno::EPIPE: Broken pipe - <STDERR>

Try killing it, and running it again. First find the process id:

    ps aux | grep shotgun

which outputs something like:

    25:ttt      44616   0.1  0.8  2471192  32192 s000  S+   11:45am   0:02.94 ruby /Users/ttt/.rbenv/versions/1.9.2-p290/lib/ruby/gems/1.9.1/bin/shotgun --server=thin config.ru -p 6100
    122:ttt      44653   0.0  0.0  2425700    264 s001  R+   11:46am   0:00.00 grep -n shotgun

The 2nd column is the process id, so to kill the shotgun server from the previous output, you would run

    kill 44616

Then run the server again.