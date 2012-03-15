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
  many :user_timetables

  # Validations
  validates_format_of :email, :with => /\b[a-zA-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i


  #############################################################################
  # Public methods
  #############################################################################

  def to_hash
    { "id" => self.id.to_s, "uid" => self.uid, "name" => self.name, "email" => self.email }
  end
end
