module Api
  module V1
    class PlacesController < BaseController
      def index
        coordinates = Coordinates.parse(params[:near])
        return render_failure(:invalid_location) unless coordinates

        render json: PlacesSerializer.new(NearbyPlaces.new.call(coordinates))
      end

      def create
        return render_failure(:forbidden) unless PlacePolicy.new(current_user).create?

        result = ::Places::Create.new.call(created_by: current_user, attributes: place_params)
        render_result(result, status: :created) { |place| PlaceSerializer.new(place) }
      end

      private

      def place_params
        params.permit(:name, :latitude, :longitude, :radius_m, :dwell_seconds).to_h.symbolize_keys
      end
    end
  end
end
