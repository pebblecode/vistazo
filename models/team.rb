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

    self.user_timetables.delete_if { |ut| ut.user_id == user.id } 
    self.save
  end

  def user_timetables_in_week(week_num)
    user_timetables = self.user_timetables

    user_timetables.each do |ut|
      ut.timetable_items = ut.timetable_items.select { |ti| ti.date.strftime("%U") == week_num.to_s }
    end

    user_timetables
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

  # Convenience method to access a users timetable items(user)
  def user_timetable_items(user)
    user = user_timetable(user)
    user.timetable_items
  end
  
  # Returns the timetable item added, or nil if it isn't saved properly
  def add_timetable_item(user, project, date)
    user_timetable = self.user_timetable(user) ? self.user_timetable(user) : UserTimetable.new(:user => user, :team => self)
    
    ttItem = TimetableItem.new(:project => project, :date => date)
    user_timetable.timetable_items ||= []
    user_timetable.timetable_items << ttItem

    self.user_timetables ||= []
    self.user_timetables.delete_if { |ut| ut.user == user }
    self.user_timetables << user_timetable
    
    self.save ? ttItem : nil
  end

  def delete_timetable_item_with_id!(user, timetable_item_id)
    user_timetable = self.user_timetable(user)
    
    user_timetable.timetable_items.reject! { |ttItem| ttItem.id.to_s == timetable_item_id.to_s }

    self.save
  end

  def delete_project_in_timetables!(project)
    self.user_timetables.each do |user_timetable|
      user_timetable.timetable_items.reject! { |ttItem| ttItem.project_id == project.id }
    end

    self.save
  end

  def update_timetable_item(timetable_item, from_user, to_user, to_date)
    # puts "Update from #{from_user.name} (#{timetable_item.to_s}) to #{to_user.name} (#{to_date})"
    project_id = timetable_item.project_id
    
    timetable_item.date = to_date
    
    if from_user != to_user
      did_delete = self.delete_timetable_item_with_id!(from_user, timetable_item.id)

      if did_delete
        to_user_timetable = self.user_timetable(to_user)

        to_user_timetable.timetable_items ||= []
        to_user_timetable.timetable_items << timetable_item

      else
        return false
      end
    end
    
    self.save
  end

  def url_slug
    self.id.to_s
  end
end