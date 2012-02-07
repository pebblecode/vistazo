class TimetableItem
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::Plugins::Timestamps
  
  before_save :cache_project_name
  
  key :date, Date, :required => true
  
  # Cache project
  key :project_name, String
  
  timestamps!
  
  # Relationships
  one :project
  
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