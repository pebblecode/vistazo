class TeamMemberProject
  include MongoMapper::EmbeddedDocument
  before_save :cache_project_name
  
  key :date, Date, :required => true
  
  # Cache project
  key :project_name, String
  
  # Relationships
  one :project
  
  def css_class
    get_project_css_class(self.project_name)
  end
  
  private
  
  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end
end