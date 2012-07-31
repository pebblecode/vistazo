# Colours to cycle through for projects.
COLOURS = [
    { :light_green => "#afce3f" },
    { :purple => "#ae3fce" },
    { :orange => "#eeb028" },
    { :light_blue => "#3fa9ce" },
    { :red => "#e22626" },
    { :medium_green => "#3fce68" },
    { :pink => "#f118ad" },
    { :yellow => "#fede4f" },
    { :aqua => "#1ee4bc" },
    { :dark_blue => "#5f4bd5" },
  ]
class ColourSetting
  include MongoMapper::Document

  key :last_hex_colour_saved, String
end