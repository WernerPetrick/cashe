class PlaceSerializer
  def initialize(place)
    @place = place
  end

  def as_json(*)
    { id: @place.id, name: @place.name, latitude: @place.latitude, longitude: @place.longitude,
      radius_m: @place.radius_m, dwell_seconds: @place.dwell_seconds }.merge(distance)
  end

  private

  # Only present on nearby-search results.
  def distance
    @place.has_attribute?(:distance_m) ? { distance_m: @place.distance_m.round } : {}
  end
end
