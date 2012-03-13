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
  many :timetable_items

  # Validations
  validates_format_of :email, :with => /\b[a-zA-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i


  #############################################################################
  # Public methods
  #############################################################################

  def to_hash
    { "id" => self.id.to_s, "uid" => self.uid, "name" => self.name, "email" => self.email }
  end

    # Returns the timetable item added, or nil if it isn't saved properly
  def add_project_on_date(project, date)
    # TODO: Check that it gets saved! Mongo doesn't check by default
    timetable_item = TimetableItem.new(:project_id => project.id, :date => date)
    self.timetable_items << timetable_item
    
    self.save ? timetable_item : nil
  end
  
  def move_project(timetable_item, to_user, to_date)
    # puts "Moving from #{self.name} (#{timetable_item}) to #{to_user.name} on #{to_date}"
    project_id = timetable_item.project_id
    
    timetable_item.date = to_date
    self.save
    
    if self != to_user
      did_delete = self.timetable_items.reject! { |proj| proj == timetable_item }
      self.save
      # puts "Team member should still exist: #{timetable_item}"
      unless did_delete.nil?
        to_user.timetable_items << timetable_item
        to_user.save
      else
        return false
      end
    end
    
    return true
  end
end
