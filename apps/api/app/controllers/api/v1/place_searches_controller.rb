module Api
  module V1
    # Real-world places from the outside place search (ADR 0006). Every call reaches
    # Photon, so it's rate-limited per user.
    class PlaceSearchesController < BaseController
      rate_limit to: 30, within: 1.minute, by: -> { rate_limit_key }, with: -> { render_failure(:rate_limited) }
      rescue_from PlaceSearch::Unavailable, with: -> { render_failure(:place_search_unavailable) }

      def index
        result = ::Places::Search.new.call(query: params[:q], near: Coordinates.parse(params[:near]))
        render_result(result) { |hits| PlaceSearchSerializer.new(hits) }
      end
    end
  end
end
