module DateHelper
  # The week number right now
  #
  # @return {String} Week from 1 to 52 inclusive
  def week_num_now
    week_num(Time.now)
  end

  # @param {Date} The date to check
  # @return {Boolean} Whether the date is today or not
  def is_today?(date)
    (date.year == Time.now.year) and (date.month == Time.now.month) and (date.day == Time.now.day)
  end

  # Get the week number from the time, from 1 to 52 inclusive.
  #
  # @param {Time} time The time
  # @return {String} Week from 1 to 52 inclusive
  def week_num(time)
    time_week = time.strftime("%U")
    case time_week
    when "00"
      "1" # Move forward, because strftime starts from 0
    when "53"
      "52" # Move back, because strftime ends at 53
    else
      time_week
    end
  end

  # Get the week range for the given year
  def week_range(year)
    start_week = Time.parse("#{year}-1-1").strftime("%U").to_i
    end_week = Time.parse("#{year}-12-31").strftime("%U").to_i

    start_week..end_week
  end

  # Get previous week's year. If it is the first week of the
  # year, return the previous year
  def prev_week_year(week, year)
    prev_week = week - 1
    previous_week_year = year

    if prev_week < week_range(year).first
      previous_week_year = year - 1
    end

    previous_week_year
  end

  # Get the previous week number. If it is the first week of the
  # year, return the last week of the previous year
  def prev_week_num(week, year)
    prev_week = week - 1

    if prev_week < week_range(year).first
      prev_week = week_range(year - 1).last
    end

    prev_week
  end

  # Get next week's year. If it is the last week of the
  # year, return the next year
  def next_week_year(week, year)
    next_week = week + 1
    n_week_year = year

    if next_week > week_range(year).last
      n_week_year = year + 1
    end

    n_week_year
  end

  # Get the next week number. If it is the last week of the
  # year, return the first week of the next year
  def next_week_num(week, year)
    next_week = week + 1

    if next_week > week_range(year).last
      next_week = week_range(year + 1).first
    end

    next_week
  end
end