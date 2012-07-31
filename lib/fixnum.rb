require "date"

class Fixnum
  def ordinalize
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
        when 1; "#{self}st"
        when 2; "#{self}nd"
        when 3; "#{self}rd"
        else    "#{self}th"
      end
    end
  end

  def to_abbr_month_name
    # Just use any year and day - what the abbreviated month name
    Date.new(2012, self, 1).strftime("%b")
  end
end
