class Account
  include MongoMapper::Document

  key :name, String, :required => true

  timestamps!

  # Relationships
  many :team_members
  many :projects
  many :users


  def url_slug
    self.id.to_s
  end
end