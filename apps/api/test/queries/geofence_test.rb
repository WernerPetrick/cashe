require "test_helper"

class GeofenceTest < ActiveSupport::TestCase
  def contains?(latitude, longitude)
    Geofence.new.contains?(places(:tuckshop), Coordinates.new(latitude: latitude, longitude: longitude))
  end

  test "includes the centre and points inside the radius" do
    assert contains?(-33.9249, 18.4241)
    assert contains?(-33.92455, 18.4241) # ~39 m north
  end

  test "excludes points beyond the radius" do
    assert_not contains?(-33.92440, 18.4241) # ~56 m north
  end

  test "keeps coordinates out of the SQL log" do
    log = StringIO.new
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(log)
    contains?(-33.9249, 18.4241)

    assert_no_match(/33\.92|18\.42/, log.string)
  ensure
    ActiveRecord::Base.logger = Rails.logger
  end
end
