class TeamMember
  include MongoMapper::Document

  key :name, String, :required => true

  timestamps!

  # Relationships
  many :timetable_items
  belongs_to :team
  
  # Returns the timetable item added, or nil if it isn't saved properly
  def add_project_on_date(project, date)
    # TODO: Check that it gets saved! Mongo doesn't check by default
    timetable_item = TimetableItem.new(:project_id => project.id, :date => date)
    self.timetable_items << timetable_item
    
    self.save ? timetable_item : nil
  end
  
  def move_project(timetable_item, to_team_member, to_date)
    # puts "Moving from #{self.name} (#{timetable_item}) to #{to_team_member.name} on #{to_date}"
    project_id = timetable_item.project_id
    
    timetable_item.date = to_date
    self.save
    
    if self != to_team_member
      did_delete = self.timetable_items.reject! { |proj| proj == timetable_item }
      self.save
      # puts "Team member should still exist: #{timetable_item}"
      unless did_delete.nil?
        to_team_member.timetable_items << timetable_item
        to_team_member.save
      else
        return false
      end
    end
    
    return true
  end
end
