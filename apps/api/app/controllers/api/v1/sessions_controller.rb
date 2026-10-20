module Api
  module V1
    # Exchanges an Appwrite JWT for the Cashe user; authentication creates it on first call.
    class SessionsController < BaseController
      def create
        render json: UserSerializer.new(current_user)
      end
    end
  end
end
