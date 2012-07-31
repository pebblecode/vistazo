class TimetableItem
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Timestamps

  before_save :cache_project_name, :cache_date, :cache_user, :cache_team

  key :date, Date, :required => true

  # Cache values
  key :project_name, String
  key :week_num, Integer
  key :year, Integer
  key :month, Integer

  timestamps!

  # Relationships
  belongs_to :project
  belongs_to :user_timetable

  # Cache relationships (derived from user_timetable)
  belongs_to :team
  belongs_to :user

  def css_class
    get_project_css_class(self.project_id.to_s)
  end

  #############################################################################
  # Public methods
  #############################################################################

  # Create a TimetableItem with a team and a user. Needed because
  # when user_timetable caches team and user from user_timetable
  #
  # Returns nil if user_timetable not found.
  def self.create_with_team_id_and_user_id(team_id, user_id, create_params)
    user_timetable = UserTimetable.find_by_team_id_and_user_id(team_id, user_id)

    timetable_item = self.create(create_params.merge({:user_timetable => user_timetable})) unless user_timetable.nil?

    timetable_item
  end

  def self.by_team_year_week(team, year, week_num)
    where(:team_id => team.id, :year => year.to_i, :week_num => week_num.to_i)
  end

  def self.by_team_year_month(team, year, month)
    where(:team_id => team.id, :year => year.to_i, :month => month.to_i)
  end


  #############################################################################
  # Override to_json to sanitize output
  #############################################################################

  def serializable_hash(options = {})
    pre_sanitized_hash = super({
      :only => [:id, :date, :project_name, :project_id, :user_id, :team_id, :user_timetable_id]
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

  def cache_date
    self.week_num = self.date.strftime("%U").to_i
    self.month = self.date.month.to_i
    self.year = self.date.year.to_i
  end

  def cache_user
    self.user = self.user_timetable.user if self.user_timetable
  end

  def cache_team
    self.team = self.user_timetable.team if self.user_timetable
  end
end