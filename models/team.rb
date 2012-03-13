class Team
  include MongoMapper::Document

  key :name, String, :required => true
  
  timestamps!

  # Relationships
  many :projects

  #############################################################################
  # Class methods
  #############################################################################
  
  def self.create_for_user(user)
    new_user_team = Team.create(:name => "#{user.name}'s team")
    new_user_team.add_user(user)
    
    user.teams << new_user_team
    user.save
    
    return new_user_team
  end

  #############################################################################
  # Public methods
  #############################################################################

  def add_user(user)
    user.teams << self
    user.save
  end
  
  # def activate_user(user)
  #   self.pending_users.delete_if {|u| u["id"] == user.id.to_s}
    
  #   self.active_users.delete_if {|u| u["id"] == user.id.to_s} # Delete it, so it can be re-added
  #   self.active_users << user.to_hash
    
  #   user.teams << self
  #   user.save
    
  #   self.save
  # end
  
  def url_slug
    self.id.to_s
  end
end