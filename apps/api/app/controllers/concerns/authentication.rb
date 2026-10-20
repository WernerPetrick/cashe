# Requires a valid Appwrite JWT (`Authorization: Bearer <jwt>`) and exposes current_user.
module Authentication
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate!
    rescue_from AppwriteAuth::Unavailable, with: :auth_unavailable
    attr_reader :current_user
  end

  private

  def authenticate!
    result = Users::Authenticate.new.call(token: bearer_token)
    return @current_user = result.value if result.success?

    render_error(:unauthorized, "unauthorized", "A valid Appwrite JWT is required.")
  end

  def bearer_token
    authenticate_with_http_token { |token, _options| token }
  end

  def auth_unavailable
    render_error(:service_unavailable, "auth_unavailable", "Sign-in could not be checked. Try again.")
  end
end
