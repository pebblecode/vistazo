# Rake file to help with Vistazo development
require 'fileutils'

#####################################################################
# Server
#####################################################################

desc "Start the server using the development Procfile."
task "server" do
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
end