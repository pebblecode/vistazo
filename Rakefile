# Rake file to help with Vistazo development
require 'fileutils'

desc "Start the server using the development Procfile."
task "server" do
  start_server_cmd = "foreman start -f Procfile_development"
  sh start_server_cmd
end

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

# Test rake tasks
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
