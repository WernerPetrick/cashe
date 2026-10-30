class PlaceSearchSerializer
  def initialize(hits)
    @hits = hits
  end

  def as_json(*)
    { results: @hits.map(&:to_h) }
  end
end
