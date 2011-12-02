class TeamMember
  include MongoMapper::Document

  key :name, String, :required => true

  timestamps!

  # Relationships
  many :team_member_projects
  belongs_to :account
  
  def add_project_on_date(project, date)
    # TODO: Check that it gets saved! Mongo doesn't check by default
    self.team_member_projects << TeamMemberProject.new(:project_id => project.id, :date => date)
    self.save
  end
  
  def move_project(team_member_project, to_team_member, to_date)
    puts "Moving from #{self.name} (#{team_member_project}) to #{to_team_member.name} on #{to_date}"
    project_id = team_member_project.project_id
    
    team_member_project.date = to_date
    self.save
    
    if self != to_team_member
      did_delete = self.team_member_projects.reject! { |proj| proj == team_member_project }
      self.save
      puts "Team member should still exist: #{team_member_project}"
      unless did_delete.nil?
        to_team_member.team_member_projects << team_member_project
        to_team_member.save
      else
        return false
      end
    end
    
    return true
  end
end
