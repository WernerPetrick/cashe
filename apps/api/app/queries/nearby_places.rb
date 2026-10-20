# Places within a radius of a point, nearest first, with their distance in metres.
class NearbyPlaces
  include QuietSql

  POINT = "ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography"

  def initialize(radius_m: 5_000, limit: 50)
    @radius_m = radius_m
    @limit = limit
  end

  def call(coordinates)
    binds = { lng: coordinates.longitude, lat: coordinates.latitude, radius: @radius_m }
    without_sql_log { scope(binds).to_a }
  end

  private

  def scope(binds)
    distance = Place.sanitize_sql_array([ "ST_Distance(places.location, #{POINT})", binds ])
    Place.select("places.*, #{distance} AS distance_m").where("ST_DWithin(places.location, #{POINT}, :radius)", binds)
      .order(Arel.sql("distance_m")).limit(@limit)
  end
end
