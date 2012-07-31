class Team
  include MongoMapper::Document

  key :name, String, :required => true

  timestamps!

  # Relationships
  many :projects
  many :user_timetables

  #############################################################################
  # Class methods
  #############################################################################

  # Create a team for a user. Adds the user to the team, and adds
  # the team to the user
  def self.create_for_user(user)
    new_user_team = Team.create(:name => "#{user.name}'s team")
    new_user_team.add_user(user)

    user.teams << new_user_team
    user.save

    return new_user_team
  end

  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({
      :only => [:id, :name]
    }.merge(options))

    # Sanitize
    pre_sanitized_hash.merge({
      "name" => Rack::Utils.escape_html(self.name)
    })
  end

  #############################################################################
  # Public methods
  #############################################################################

  def add_user(user, is_visible = true)
    user.teams << self
    user.save

    self.user_timetables << UserTimetable.new(:user => user, :team => self, :is_visible => is_visible)
    self.save
  end

  # Delete the user from the team, both in the user team ids and the
  # team user timetables
  def delete_user(user)
    user.team_ids.delete_if { |tid| tid == self.id }
    user.save

    UserTimetable.delete_all({:user_id => user.id, :team_id => self.id})
    TimetableItem.delete_all({:user_id => user.id, :team_id => self.id})
  end

  def has_user_timetable?(user)
    self.user_timetables.select { |ut| ut.user == user }.length > 0
  end

  def user_timetable(user)
    u_timetable = self.user_timetables.select { |ut| ut.user == user }

    u_timetable.present? ? u_timetable.first : nil
  end

  def set_user_timetable_is_visible(user, is_visible)
    user_timetable = self.user_timetables.select { |ut| ut.user == user }.first
    user_timetable.is_visible = is_visible

    self.user_timetables.delete_if { |ut| ut.user == user }
    self.user_timetables << user_timetable

    self.save
  end

  def delete_project_in_timetables!(project)
    TimetableItem.delete_all({:team_id => self.id, :project_id => project.id})
    Project.delete(project.id)
  end

  def url_slug
    self.id.to_s
  end
end