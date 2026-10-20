class PlacesSerializer
  def initialize(places)
    @places = places
  end

  def as_json(*)
    { places: @places.map { |place| PlaceSerializer.new(place).as_json } }
  end
end
