class UserTimetable
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Timestamps

  key :is_visible, Boolean, :default => true

  timestamps!

  # Relationships
  belongs_to :team
  belongs_to :user
  many :timetable_items

  def css_class
    get_project_css_class(self.project_id.to_s)
  end

  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({
      :only => [:id, :is_visible, :user_id, :team_id, :timetable_items]
    }.merge(options))
  end

end

#############################################################################
# Indexes
#############################################################################

# Only need to search by team, or team and user, never by user
UserTimetable.ensure_index([[:team_id, 1], [:user_id, 1]])