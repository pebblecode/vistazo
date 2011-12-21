class User
  include MongoMapper::Document

  key :name, String
  key :uid, String
  key :email, String, :required => true

  timestamps!

  # Relationships
  many :teams

  # Validations
  validates_format_of :email, :with => /\b[a-zA-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
  # validates_presence_of :team_id  # Need it to be nil, so that a user can be created before the team is created


  #############################################################################
  # Public methods
  #############################################################################

  def cache_hash
    { :id => self.id.to_s, :uid => self.uid, :name => self.name, :email => self.email }
  end
end
