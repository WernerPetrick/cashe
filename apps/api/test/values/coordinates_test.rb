require "test_helper"

class CoordinatesTest < ActiveSupport::TestCase
  test "holds a latitude and longitude" do
    point = Coordinates.new(latitude: -33.9249, longitude: 18.4241)

    assert_in_delta(-33.9249, point.latitude)
    assert_in_delta 18.4241, point.longitude
  end

  test "rejects values off the globe" do
    assert_raises(ArgumentError) { Coordinates.new(latitude: 91, longitude: 0) }
    assert_raises(ArgumentError) { Coordinates.new(latitude: 0, longitude: -181) }
  end

  test "rejects values that aren't numbers" do
    assert_raises(ArgumentError) { Coordinates.new(latitude: "x", longitude: 0) }
  end

  test "parses a lat,lng string" do
    point = Coordinates.parse("-33.9249,18.4241")

    assert_in_delta 18.4241, point.longitude
  end

  test "parse returns nil for junk" do
    assert_nil Coordinates.parse("nowhere")
    assert_nil Coordinates.parse(nil)
  end

  test "never prints the location" do
    point = Coordinates.new(latitude: -33.9249, longitude: 18.4241)

    assert_no_match(/33\.92|18\.42/, point.inspect)
    assert_no_match(/33\.92|18\.42/, point.to_s)
  end
end
