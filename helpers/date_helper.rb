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
end