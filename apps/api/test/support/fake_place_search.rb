# Stands in for PlaceSearch::Photon: answers every query with the same hits.
class FakePlaceSearch
  attr_reader :searches

  def initialize(hits = [], unavailable: false)
    @hits = hits
    @unavailable = unavailable
    @searches = []
  end

  def search(query, near:, limit:)
    raise PlaceSearch::Unavailable, "down" if @unavailable

    @searches << { query: query, near: near, limit: limit }
    @hits
  end
end
