class TimeWindowSerializer
  def initialize(window)
    @window = window
  end

  def as_json(*)
    { days_of_week: @window.days_of_week, starts_at: @window.starts_at.strftime("%H:%M"),
      ends_at: @window.ends_at.strftime("%H:%M"), time_zone: @window.time_zone }
  end
end
