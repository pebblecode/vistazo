class TimetableItem
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::Plugins::Timestamps
  
  before_save :cache_project_name
  
  key :date, Date, :required => true
  
  # Cache project
  key :project_name, String
  
  timestamps!
  
  # Relationships
  belongs_to :project
  
  def css_class
    get_project_css_class(self.project_id.to_s)
  end
  

  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({ 
      :only => [:id, :date, :project_name, :project_id]
    }.merge(options))

    # Sanitize
    pre_sanitized_hash.merge({
      "project_name" => Rack::Utils.escape_html(self.project_name)
    })
  end

  private
  
  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end
end