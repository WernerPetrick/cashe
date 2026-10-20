# A point on the globe from a presence ping. Used for a check, then discarded:
# it never prints its values, so it can't leak into logs (privacy rules).
class Coordinates
  attr_reader :latitude, :longitude

  # "lat,lng" → Coordinates, or nil when it can't be read.
  def self.parse(text)
    latitude, longitude = text.to_s.split(",", 2)
    new(latitude: Float(latitude), longitude: Float(longitude))
  rescue ArgumentError, TypeError
    nil
  end

  def initialize(latitude:, longitude:)
    @latitude = coordinate(latitude, 90)
    @longitude = coordinate(longitude, 180)
    freeze
  end

  # A geographic point for PostGIS (longitude first, as WKT expects).
  def to_point
    RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
  end

  def inspect
    "#<Coordinates [redacted]>"
  end
  alias to_s inspect

  private

  def coordinate(value, limit)
    number = Float(value)
    raise ArgumentError, "coordinate out of range" unless number.abs <= limit

    number
  rescue TypeError
    raise ArgumentError, "coordinate must be a number"
  end
end
