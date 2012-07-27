class TimetableItem
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Timestamps

  before_save :cache_project_name, :cache_week_num, :cache_year

  key :date, Date, :required => true

  # Cache values
  key :project_name, String
  key :week_num, Integer
  key :year, Integer

  timestamps!

  # Relationships
  belongs_to :project
  belongs_to :user_timetable
  belongs_to :team
  belongs_to :user

  def css_class
    get_project_css_class(self.project_id.to_s)
  end

  #############################################################################
  # Public methods
  #############################################################################

  def self.by_team_year_week(team, year, week_num)
    where(:team_id => team.id, :year => year.to_i, :week_num => week_num.to_i)
  end

  def user_timetables_in_month(month)
    # TODO
    # user_timetables = self.user_timetables

    # user_timetables.each do |ut|
    #   ut.timetable_items = ut.timetable_items.select { |ti| ti.date.month.to_s == month.to_s }
    # end

    # user_timetables
  end


  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({
      :only => [:id, :date, :project_name, :project_id, :user_id]
    }.merge(options))

    # Sanitize
    pre_sanitized_hash.merge({
      "project_name" => Rack::Utils.escape_html(self.project_name)
    })
  end

  private

  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end

  def cache_week_num
    self.week_num = self.date.strftime("%U").to_i
  end

  def cache_year
    self.year = self.date.year.to_i
  end
end