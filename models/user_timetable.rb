class UserTimetable
  include MongoMapper::EmbeddedDocument
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
  
  private
  
  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end
end