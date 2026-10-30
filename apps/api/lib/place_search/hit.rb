module PlaceSearch
  # A real-world place from the search. Its point is public (a shop, a school),
  # not a person's location, so it can be returned to the app.
  Hit = Data.define(:name, :address, :latitude, :longitude)
end
