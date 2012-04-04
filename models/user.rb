class User
  include MongoMapper::Document

  key :name, String
  key :uid, String
  key :email, String, :required => true
  key :team_ids, Array
  key :is_new, Boolean, :default => true

  timestamps!

  # Relationships
  many :teams, :in => :team_ids

  # Validations
  validates_format_of :email, :with => /\b[a-zA-Z0-9._%-\+]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i


  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({ 
      :only => [:id, :name, :email] 
    }.merge(options))

    # Sanitize
    pre_sanitized_hash.merge({
      "name" => Rack::Utils.escape_html(self.name), 
      "email" => Rack::Utils.escape_html(self.email)
    })
  end

  #############################################################################
  # Public methods
  #############################################################################

  def to_hash
    { "id" => self.id.to_s, "uid" => self.uid, "name" => self.name, "email" => self.email }
  end

  def has_a_team?
    self.team_ids.length > 0
  end

  def remove_team(team)
    self.teams = self.teams.delete_if { |t| t == team }
    self.save
  end
end
