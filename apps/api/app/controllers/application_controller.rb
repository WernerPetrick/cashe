class ApplicationController < ActionController::API
  private

  def render_error(status, code, message)
    render json: { error: { code: code, message: message } }, status: status
  end
end
