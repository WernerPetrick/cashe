require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  ALWAYS_NO = Struct.new(:x) { def include?(_) = false }.new
  ALWAYS_YES = Struct.new(:x) { def include?(_) = true }.new

  test "is open any time without windows" do
    assert Schedule.new([]).open_at?(Time.current)
  end

  test "is open when any window includes the time" do
    assert Schedule.new([ ALWAYS_NO, ALWAYS_YES ]).open_at?(Time.current)
    assert_not Schedule.new([ ALWAYS_NO ]).open_at?(Time.current)
  end
end
