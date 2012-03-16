# To create a new project use
#
#      Project.create(:name => "ideapi")
#
# The class will figure out the hex colour for you. If you specify a 
# `:hex_colour` explicitly, this will still be stored, however, if the colour
# is not in `COLOURS`, the next project added will use the first colour in
# `COLOURS`
class Project
  include MongoMapper::Document
  before_save :save_hex_colour

  key :name, String, :required => true
  key :hex_colour, String
  
  timestamps!

  # Relationships
  belongs_to :team

  def css_class
    get_project_css_class(self.id.to_s)
  end

  private

  def save_hex_colour
    unless self.hex_colour.present?
      # Find next colour from teh last save
      last_colour_setting = ColourSetting.first
      if last_colour_setting.present?
        last_colour_index = COLOURS.index{ |c| c.values.include? last_colour_setting.last_hex_colour_saved }

        self.hex_colour = last_colour_index.present? ? 
                            COLOURS[(last_colour_index + 1) % COLOURS.length].values[0] :
                            COLOURS[0].values[0]
      else
        self.hex_colour = COLOURS[0].values[0]
      end

      save_hex_colour_used_in_settings
    end
  end

  def save_hex_colour_used_in_settings
    # TODO: There must be an easier way to update! Try push/set?
    colour_setting = ColourSetting.first
    if colour_setting.present?
      colour_setting.last_hex_colour_saved = self.hex_colour
      colour_setting.save
    else
      ColourSetting.create(:last_hex_colour_saved => self.hex_colour)
    end
  end

end