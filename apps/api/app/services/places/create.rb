module Places
  class Create
    def call(created_by:, attributes:)
      place = Place.new(attributes.except(:latitude, :longitude).merge(created_by: created_by, location: point(attributes)))
      place.save ? Result.success(place) : Result.failure(:validation_failed, place.errors.full_messages)
    end

    private

    # A place's centre is public, unlike a person's location, so it is stored.
    def point(attributes)
      Coordinates.new(latitude: attributes[:latitude], longitude: attributes[:longitude]).to_point
    rescue ArgumentError
      nil
    end
  end
end
