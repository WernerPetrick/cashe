require "test_helper"

class DwellProgressTest < ActiveSupport::TestCase
  ENTERED = Time.utc(2026, 10, 21, 10, 30)

  def progress(seconds_later, required: 30)
    DwellProgress.new(entered_at: ENTERED, now: ENTERED + seconds_later, required_seconds: required)
  end

  test "counts whole seconds since entering" do
    assert_equal 12, progress(12.7).elapsed_seconds
    assert_not_predicate progress(12), :complete?
  end

  test "is complete once the required time has passed" do
    assert_predicate progress(30), :complete?
  end

  test "never reports more than required" do
    assert_equal 30, progress(95).elapsed_seconds
  end

  test "never goes negative" do
    assert_equal 0, progress(-5).elapsed_seconds
  end
end
