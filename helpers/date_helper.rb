# Extend date object with helpers
class Date
  # The week number right now
  #
  # @return {String} Week from 1 to 52 inclusive
  def self.week_num_now
    week_num(Time.now)
  end

  # @param {Date} The date to check
  # @return {Boolean} Whether the date is today or not
  def self.is_today?(date)
    (date.year == Time.now.year) and (date.month == Time.now.month) and (date.day == Time.now.day)
  end

  # Get the week number from the time. Uses ISO 8601 format.
  # Note that a date can exist at the start of a year and be
  # in the week at the end of the previous year, and vice versa.
  # See http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime
  #
  # @param {Time} time The time
  # @return {String} Week from 1 to 53 inclusive
  def self.week_num(time)
    time.strftime("%V")
  end

  # Get the year based on the week, using the ISO 8601 format.
  # Note that a date can exist at the start of a year and be
  # in the previous year, and vice versa.
  # See http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime
  #
  # @param {Time} time The time
  # @return {String} Week based year
  def self.week_year(time)
    time.strftime("%G")
  end

  # Get the week range for the given year.
  # Note, week starts from Monday, as per "%W" of http://ruby-doc.org/stdlib-1.9.3/libdoc/date/rdoc/Date.html#method-i-strftime
  def self.week_range(year)
    start_week = 1

    last_day_of_year = Time.parse("#{year}-12-31")
    end_week = (last_day_of_year.strftime("%V") == "53") ? 53 : 52

    start_week..end_week
  end

  # Get previous week's year. If it is the first week of the
  # year, return the previous year
  def self.prev_week_year(week, year)
    prev_week = week - 1
    previous_week_year = year

    if prev_week < week_range(year).first
      previous_week_year = year - 1
    end

    previous_week_year
  end

  # Get the previous week number. If it is the first week of the
  # year, return the last week of the previous year
  def self.prev_week_num(week, year)
    prev_week = week - 1

    if prev_week < week_range(year).first
      prev_week = week_range(year - 1).last
    end

    prev_week
  end

  # Get next week's year. If it is the last week of the
  # year, return the next year
  def self.next_week_year(week, year)
    next_week = week + 1
    n_week_year = year

    if next_week > week_range(year).last
      n_week_year = year + 1
    end

    n_week_year
  end

  # Get the next week number. If it is the last week of the
  # year, return the first week of the next year
  def self.next_week_num(week, year)
    next_week = week + 1

    if next_week > week_range(year).last
      next_week = week_range(year + 1).first
    end

    next_week
  end
end