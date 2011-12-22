class Team
  include MongoMapper::Document

  key :name, String, :required => true
  
  # Cache of user objects, stored as user hash values
  key :active_users, Array
  key :pending_users, Array
  
  timestamps!

  # Relationships
  many :team_members
  many :projects

  #############################################################################
  # Public methods
  #############################################################################
  
  def self.create_for_user(user)
    new_user_team = Team.create(:name => "#{user.name}'s team")
    new_user_team.add_user_with_status(user, :active)
    
    user.teams << new_user_team
    user.save
    
    return new_user_team
  end
  
  def add_user(user)
    add_user_with_status(user, :pending)
  end
  
  def add_user_with_status(user, status)
    if (status == :active)
      self.active_users << user.to_hash
      user.teams << self
      user.save
    elsif (status == :pending)
      self.pending_users << user.to_hash
      user.teams << self
      user.save
    else
      return false
    end
  end
  
  def has_active_user?(user)
    self.active_users.include? user.to_hash
  end
    
  def has_pending_user?(user)
    self.pending_users.include? user.to_hash
  end
  
  def url_slug
    self.id.to_s
  end
end