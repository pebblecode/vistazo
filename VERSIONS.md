# 0.11.0

* Month view
* Remove reset route and use rake task instead
* Don't show javascript flashes
* Bug fixes

# 0.10.0

* Major architectural change in user/team members/teams. Combine the
  concept of user and team members, and calling them all users. Removed
  users dialog (manage it through the user name button)
* Ability to show and hide users from the timetable (visible users vs
  other users)
* Add form validation on front end
* Homepage updates
* Add press kit
* Update form styles
* Security enhancements: sanitize output, filter out non-necessary
  model attributes in `to_json`
* Fixed up most tests

# 0.9.0

* Project view
* Help page fix
* Bug fixes

# 0.8.0

* Fluid layout
* Delete projects
* Ajaxify new project, delete project, and add team member
* Bug fixes

# 0.7.1

* Add weekends to week view
* Highlight today column

# 0.7.0

* New teams
* Bugs

# 0.6.1

* Fixed #151 - pending user showing up as switchable team

# 0.6.0

* Multiple teams feature
* Migration for multiple teams

# 0.5.1

* UX updates based on user testing
* Clean up
* Some more testing

# 0.5.0

* Update homepage
* Update registration page
* Error page
* Hover states
* Favicon
* Help overlay
* Footer
* Delete team member
* Edit team member name
* Edit account name
* Domain redirects
* Tests
* Clean up

# 0.4.0

* Sign up workflow
* Invite user functionality
* Testing framework with authentication tests
* New homepage

# 0.3.0

* Design and code clean up
* Ability store different projects/team members in different accounts
* Ability to add new team members in an account

# 0.1.0

* Create staging/production branches
* Change /create and /delete_all to just /reset post to clear out the database
* Bug fix

# 0.0.7

* Drag and drop
* Automatic colour selection for new projects
* Escape html in view
* Some clean up of code

# 0.0.6

* Can add delete projects

# 0.0.5

* Can add new projects

# 0.0.4

* Sort team members/projects
* Changed team member project url
* Flash messages

# 0.0.3

* Set up project
* Put in design layout
* Seed data in code
* Clear database
* Can add existing project