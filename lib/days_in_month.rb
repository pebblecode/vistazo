require 'date'

# From http://stackoverflow.com/a/1489961/111884
def days_in_month(year, month)
  (Date.new(year, 12, 31) << (12-month)).day
end