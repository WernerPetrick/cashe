# A repeating window, e.g. weekdays 10:30–11:00 in Africa/Johannesburg.
# Times are seconds since local midnight; the end is exclusive.
class WeeklyWindow
  def initialize(days:, starts_at:, ends_at:, time_zone:)
    @days = days
    @starts_at = starts_at
    @ends_at = ends_at
    @time_zone = time_zone
  end

  def include?(time)
    local = time.in_time_zone(@time_zone)
    @days.include?(local.wday) && (@starts_at...@ends_at).cover?(local.seconds_since_midnight)
  end
end
