# Is a point inside a place's zone? PostGIS measures on the geography (metres).
class Geofence
  include QuietSql

  WITHIN = "ST_DWithin(places.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, places.radius_m)"

  def contains?(place, coordinates)
    without_sql_log do
      Place.where(id: place.id).where(WITHIN, lng: coordinates.longitude, lat: coordinates.latitude).exists?
    end
  end
end
