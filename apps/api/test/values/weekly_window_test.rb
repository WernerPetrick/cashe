require "test_helper"

class WeeklyWindowTest < ActiveSupport::TestCase
  # Weekdays 10:30–11:00 in Johannesburg (UTC+2).
  WINDOW = WeeklyWindow.new(days: [ 1, 2, 3, 4, 5 ], starts_at: 37_800, ends_at: 39_600, time_zone: "Africa/Johannesburg")

  def at(text) = Time.zone.parse(text)

  test "includes a weekday time inside the window, in the window's time zone" do
    assert WINDOW.include?(at("2026-10-21 08:45 UTC")) # Wednesday 10:45 SAST
  end

  test "includes the start and excludes the end" do
    assert WINDOW.include?(at("2026-10-21 08:30 UTC"))
    assert_not WINDOW.include?(at("2026-10-21 09:00 UTC"))
  end

  test "excludes the same clock time read in UTC" do
    assert_not WINDOW.include?(at("2026-10-21 10:45 UTC")) # 12:45 SAST
  end

  test "excludes weekends" do
    assert_not WINDOW.include?(at("2026-10-24 08:45 UTC")) # Saturday
  end
end
