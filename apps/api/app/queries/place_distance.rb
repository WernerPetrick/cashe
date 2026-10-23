# How far a point is from a place's centre, in whole metres. Like Geofence,
# PostGIS measures on the geography and the query never reaches the SQL log.
class PlaceDistance
  include QuietSql

  DISTANCE = "ST_Distance(places.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)"

  def call(place, coordinates)
    sql = Place.sanitize_sql_array([ DISTANCE, coordinates.longitude, coordinates.latitude ])
    without_sql_log { Place.where(id: place.id).pick(Arel.sql(sql)).round }
  end
end
