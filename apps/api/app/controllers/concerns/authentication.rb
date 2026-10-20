# Requires a valid Appwrite JWT (`Authorization: Bearer <jwt>`) and exposes current_user.
module Authentication
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate!
    rescue_from AppwriteAuth::Unavailable, with: -> { render_failure(:auth_unavailable) }
    attr_reader :current_user
  end

  private

  def authenticate!
    result = Users::Authenticate.new.call(token: bearer_token)
    return @current_user = result.value if result.success?

    render_failure(:unauthorized)
  end

  def bearer_token
    authenticate_with_http_token { |token, _options| token }
  end

  # Limits per signed-in user (falling back to IP before sign-in is known).
  def rate_limit_key
    current_user&.id || request.remote_ip
  end
end
