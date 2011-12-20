class Team
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
  
  def active_users
    self.users.select { |u| u.is_active? }
  end
  
  def pending_users
    self.users.select { |u| u.is_pending? }
  end
end