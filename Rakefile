# Rake file to help with Vistazo development
require 'fileutils'

#####################################################################
# Server
#####################################################################

desc "Start the server using the development Procfile."
task "server" do
  puts `cat Procfile_development`
  start_server_cmd = "foreman start -f Procfile_development"
  sh start_server_cmd
end


#####################################################################
# Deploy to staging/production
#####################################################################

desc "Merge branches, and push to remote server."
namespace "merge_push_to" do
  desc "Switch to branch, merge master branch and switch back to master branch. Defaults to 'staging' branch."
  task :branch, [:branch] do |t, args|
    args.with_defaults(:branch => "staging")
    checkout_merge_cmd = "git checkout #{args.branch}; git merge master"
    sh(checkout_merge_cmd) do |ok, res|
      if ok
        push_cmd = "git push origin #{args.branch}:#{args.branch}"
        sh push_cmd
        sh %{ git checkout master }
      else
        puts res
      end
    end
  end

  desc "Switch to staging branch, merge master branch and switch back to master branch."
  task :staging do |t, args|
    Rake::Task["merge_push_to:branch"].invoke("staging")
  end

  desc "Switch to production branch, merge master branch and switch back to master branch."
  task :production do |t, args|
    Rake::Task["merge_push_to:branch"].invoke("production")
  end
end

desc "Deploy branches to server."
namespace "deploy" do
  desc "Deploy branch to branch server. Defaults to staging branch."
  task :branch, [:branch] do |t, args|
    args.with_defaults(:branch => "staging")
    deploy_cmd = "git push #{args.branch} #{args.branch}:master"
    sh deploy_cmd
  end

  desc "Deploy staging branch to http://vistazo-staging.herokuapp.com/"
  task :staging do
    Rake::Task["deploy:branch"].invoke("staging")
  end

  desc "Deploy production branch to http://vistazo.herokuapp.com/"
  task :production do
    Rake::Task["deploy:branch"].invoke("production")
  end
end

desc "Ship it! Merge and pushes branches to github, then deploy them to the server."
namespace "shipit" do

  desc "Merge and push branch to github, then deploy to server."
  task :branch, [:branch] do |t, args|
    args.with_defaults(:branch => "staging")
    Rake::Task["merge_push_to:branch"].invoke(args.branch)
    Rake::Task["deploy:branch"].invoke(args.branch)
  end

  desc "Merge and push staging branch to github, then deploy to http://vistazo-staging.herokuapp.com/"
  task :staging do
    Rake::Task["shipit:branch"].invoke("staging")
  end

  desc "Merge and push production branch to github, then deploy to http://vistazo.herokuapp.com/"
  task :production do
    Rake::Task["shipit:branch"].invoke("production")
  end

end


#####################################################################
# Testing
#####################################################################

require 'rspec/core/rake_task'
desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["--color"]
    t.pattern = './spec/**/*_spec.rb'
  end
end

namespace "spec" do
  desc "Run individual spec. Can also pass in a line number."
  task :run, :spec_file, :line_number do |_, args|
    run_spec_cmd =  if args.line_number.nil?
                      "bundle exec ruby -S rspec --color #{args.spec_file}"
                    else
                      "bundle exec ruby -S rspec --color -l #{args.line_number} #{args.spec_file}"
                    end
    sh run_spec_cmd
  end
end

# Jasmine rake task
begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end


#####################################################################
# Database
#####################################################################
require 'mongo_mapper'
require_relative "lib/mongo_helper"

def ask_question(question)
  confirmation_word = "YES"

  STDOUT.flush
  puts "#{question} (#{confirmation_word} to continue)"

  input = STDIN.gets.chomp

  input == confirmation_word
end

def get_mongolab_uri(app_name)
  heroku_config_cmd = "heroku config --app #{app_name}"
  config_output = `#{heroku_config_cmd}`
  raise "Can't run #{heroku_config_cmd}" unless config_output
  puts config_output
  mongolab_uri_matches = /MONGOLAB_URI * => (.*mongolab\.com.*)$/.match(config_output)
  raise "Can't find mongo lab uri for app '#{app_name}'" unless mongolab_uri_matches

  mongolab_uri_matches[1]
end

namespace "db" do
  desc "Reset and seed database"
  namespace "reset_seed" do

    desc "Reset and seed development database from import directory"
    task :development, [:import_dir] do |task, args|
      import_dir = args.import_dir
      unless (import_dir.nil?)
        Rake::Task["db:reset:development"].invoke
        restore_cmd = "mongorestore -d vistazo-development #{import_dir}"
        puts "Running: #{restore_cmd}"
        `#{restore_cmd}`
      else
        puts "No import directory specified. Usage: bundle exec rake #{task}[import directory]"
      end
    end

    task :staging, [:import_dir] do |task, args|
      import_dir = args.import_dir
      unless (import_dir.nil?)
        url = get_mongolab_uri("vistazo-staging")
        puts "\n\nSetting up mongo connection with: #{url}"
        setup_mongo_connection(url)

        # Delete everything
        delete_all_collections

        # Import from import directory
        mongo_credentials_regex = /mongodb:\/\/(.*):(.*)@(.+:.+)\/(.*)/
        mongo_host = url.match(mongo_credentials_regex)[3]
        mongo_database = url.match(mongo_credentials_regex)[1]
        mongo_user = url.match(mongo_credentials_regex)[1]
        mongo_password = url.match(mongo_credentials_regex)[2]

        mongo_import_cmd = "mongorestore -h #{mongo_host} -d #{mongo_database} -u #{mongo_user} -p #{mongo_password} #{import_dir}"
        sh mongo_import_cmd
        puts "\n"
      else
        puts "No import directory specified. Usage: bundle exec rake #{task}[import directory]"
      end
    end

  end

  namespace "reset" do
    desc "Reset the development database"
    task :development do
      setup_mongo(:development)
      delete_all_collections
    end
    desc "Reset the development database (shorthand)"
    task :dev => :development

    desc "Reset the staging database."
    task :staging do
      if ask_question "Are you sure you want to reset the STAGING database?"

        url = get_mongolab_uri("vistazo-staging")

        puts "\n\nSetting up mongo connection with: #{url}"
        setup_mongo_connection(url)
        delete_all_collections
      else
        puts "\nExiting..."
      end
    end

    desc "Reset the sandbox database."
    task :sandbox do
      if ask_question "Are you sure you want to reset the SANDBOX database?"

        url = get_mongolab_uri("vistazo-sandbox")

        puts "\n\nSetting up mongo connection with: #{url}"
        setup_mongo_connection(url)
        delete_all_collections
      else
        puts "\nExiting..."
      end
    end

    # Commenting it out so that no one accidently resets production
    #
    # desc "Reset the production database."
    # task :production do
    #   if ask_question "Are you sure you want to reset the PRODUCTION database?"
    #     if ask_question "Are you seriously sure? Like, sure sure? It is PRODUCTION"
    #       url = get_mongolab_uri("vistazo")

    #       puts "\n\nSetting up mongo connection with: #{url}"
    #       setup_mongo_connection(url)
    #       delete_all_collections
    #     else
    #       puts "\nExiting..."
    #     end
    #   else
    #     puts "\nExiting..."
    #   end
    # end
  end

  # Set up directory in tmp/backups folder
  def setup_backup_directory(folder_prefix)
    tmp_path = "tmp"
    backups_folder = "backups"
    backups_path = "#{tmp_path}/#{backups_folder}"
    dir_path = "#{backups_path}/#{Time.now.strftime("#{folder_prefix}-%F-%H%M%S")}"

    Dir.mkdir(tmp_path) unless File::directory?(tmp_path)
    Dir.mkdir(backups_path) unless File::directory?(backups_path)
    Dir.mkdir(dir_path) unless File::directory?(dir_path)

    dir_path
  end

  namespace "backup" do
    desc "Backup the production database into the tmp directory."
    task :production do
      heroku_app_name = "vistazo"
      env_prefix = "vistazo-production"

      dir_path = setup_backup_directory(env_prefix)
      puts "Putting files in #{dir_path}"

      url = get_mongolab_uri(heroku_app_name)
      puts "\n\nSetting up mongo connection with: #{url}"
      setup_mongo_connection(url)
      mongo_credentials_regex = /mongodb:\/\/(.*):(.*)@(.+:.+)\/(.*)/
      mongo_host = url.match(mongo_credentials_regex)[3]
      mongo_database = url.match(mongo_credentials_regex)[1]
      mongo_user = url.match(mongo_credentials_regex)[1]
      mongo_password = url.match(mongo_credentials_regex)[2]

      # Download collections separately
      # MongoMapper.database.collections.each do |coll|
      #   mongo_export_cmd = "mongoexport -h #{mongo_host} -d #{mongo_database} -c #{coll.name} -u #{mongo_user} -p #{mongo_password} -o #{dir_path}/#{env_prefix}-#{coll.name}.json"
      #   sh mongo_export_cmd
      #   puts "\n"
      # end

      # Download binary
      mongo_export_cmd = "mongodump -h #{mongo_host} -d #{mongo_database} -u #{mongo_user} -p #{mongo_password} -o #{dir_path}"
      sh mongo_export_cmd
    end
  end


  def mongo_stats
    require_relative 'models/team'
    require_relative 'models/user'
    require_relative 'models/user_timetable'
    require_relative 'models/timetable_item'
    require_relative 'models/project'

    output = ""
    output += "#{Project.count} projects\n"
    output += "#{Team.count} teams\n"

    # Users
    output += "#{User.count} users\n"
    users_logged_in_last_24hrs = User.where({:last_logged_in.gte => Time.now - 1.day}).count
    output += "#{users_logged_in_last_24hrs} users logged in in the last 24hrs\n"
    output += "#{UserTimetable.count} user timetables\n"

    # Timetable items
    output += "#{TimetableItem.count} timetable items\n"

    tti_created_last_24hrs = TimetableItem.where({:created_at.gte => Time.now - 1.day}).count
    output += "#{tti_created_last_24hrs} timetable items created in the last 24hrs"

    output
  end

  namespace "stats" do
    desc "Gather statistics from the production database."
    task :production do
      url = get_mongolab_uri("vistazo")
      setup_mongo_connection(url)

      puts "\nVistazo production stats for today (#{Time.now}):"
      puts mongo_stats
    end

    require 'tinder'
    desc "Show production stats on campfire."
    task "production_campfire" do
      campfire = Tinder::Campfire.new 'pebbleit', :token => '200cd9edd594519bf230b0128c4f7d59257ae1a4', :ssl_options => { :verify => false }
      room = campfire.find_room_by_id(447461)

      url = ENV["MONGOLAB_URI"] || get_mongolab_uri("vistazo")
      setup_mongo_connection(url)
      prod_db_stats = mongo_stats

      room.speak "\nAllo! Vistazo production stats for today (#{Time.now}):"
      room.paste prod_db_stats
    end
  end

  def vistazo_users
    require_relative 'models/user'

    output = ""
    User.all.each do |user|
      output += "#{user.name} <#{user.email}>\n"
    end
    output += "\nTotal #{User.count} users\n\n"

    output
  end

  namespace "users" do
    desc "Show the users from the production database."
    task :production do
      url = get_mongolab_uri("vistazo")
      setup_mongo_connection(url)

      puts "\nVistazo users for today (#{Time.now}):\n"
      puts vistazo_users
    end
  end
end