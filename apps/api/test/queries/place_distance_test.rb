require "test_helper"

class PlaceDistanceTest < ActiveSupport::TestCase
  def distance(latitude, longitude)
    PlaceDistance.new.call(places(:tuckshop), Coordinates.new(latitude: latitude, longitude: longitude))
  end

  test "measures metres from the place's centre" do
    assert_equal 0, distance(-33.9249, 18.4241)
    assert_in_delta 200, distance(-33.9231, 18.4241), 2
  end

  test "keeps coordinates out of the SQL log" do
    log = StringIO.new
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(log)
    distance(-33.9249, 18.4241)

    assert_no_match(/33\.92|18\.42/, log.string)
  ensure
    ActiveRecord::Base.logger = Rails.logger
  end
end
