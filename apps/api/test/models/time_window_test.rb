require "test_helper"

class TimeWindowTest < ActiveSupport::TestCase
  def window(**attributes)
    TimeWindow.new(wallet: wallets(:tuckshop_gift), days_of_week: [ 1 ], starts_at: "10:30", ends_at: "11:00",
      time_zone: "Africa/Johannesburg", **attributes)
  end

  test "is valid with weekdays, an ordered range and a real time zone" do
    assert_predicate window, :valid?
  end

  test "rejects an end before the start" do
    assert_not window(ends_at: "10:00").valid?
  end

  test "rejects days outside the week" do
    assert_not window(days_of_week: [ 7 ]).valid?
  end

  test "rejects an unknown time zone" do
    assert_not window(time_zone: "Mars/Olympus").valid?
  end
end
