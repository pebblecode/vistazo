module DateHelper
  # The week number right now
  #
  # @return {String} Week from 1 to 52 inclusive
  def week_num_now
    week_num(Time.now)
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
end