# Rake file to help with Vistazo development
require 'fileutils'

desc "Merge branches, and push to remote server"
namespace "merge_push_to" do
  
  desc "Switch to branch, merge master branch and switch back to master branch. Defaults to 'staging' branch"
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

# TODO: Testing