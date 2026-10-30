module Places
  # Real-world places matching a query, biased toward a map centre (ADR 0006).
  class Search
    LIMIT = 8
    QUERY_LENGTH = 2..100

    def initialize(provider: PlaceSearch.provider)
      @provider = provider
    end

    def call(query:, near:)
      query = query.to_s.squish
      return Result.failure(:invalid_query) unless QUERY_LENGTH.cover?(query.length)
      return Result.failure(:invalid_location) unless near

      Result.success(@provider.search(query, near: near, limit: LIMIT))
    end
  end
end
