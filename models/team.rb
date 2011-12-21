class Team
  include MongoMapper::Document

  key :name, String, :required => true
  
  key :active_users, Array
  key :pending_users, Array
  
  timestamps!

  # Relationships
  many :team_members
  many :projects

  #############################################################################
  # Public methods
  #############################################################################
  
  def add_user(user)
    add_user_with_status(user, :pending)
  end
  
  def add_user_with_status(user, status)
    if (status == :active)
      self.active_users << user
    elsif (status == :pending)
      self.pending_users << user
    else
      return false
    end
  end
  
  def has_active_user?(user)
    self.active_users.include? user
  end
    
  def has_pending_user?(user)
    self.pending_users.include? user
  end
  
  def url_slug
    self.id.to_s
  end
end