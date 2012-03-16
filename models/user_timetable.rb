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
  
  private
  
  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end
end