class ApplicationController < ActionController::API
  ERROR_STATUS = {
    unauthorized: :unauthorized, forbidden: :forbidden, not_found: :not_found,
    auth_unavailable: :service_unavailable, rate_limited: :too_many_requests,
    wallet_closed: :conflict, wallet_locked: :conflict, idempotency_conflict: :conflict, not_cancellable: :conflict
  }.freeze

  rescue_from ActiveRecord::RecordNotFound, with: -> { render_failure(:not_found) }

  private

  # Every error body has the same shape: { error: { code, message, details? } }.
  def render_failure(code, details = nil)
    error = { code: code, message: I18n.t(code, scope: "api.errors") }
    error[:details] = details if details
    render json: { error: error }, status: ERROR_STATUS.fetch(code, :unprocessable_content)
  end

  def render_result(result, status: :ok)
    return render_failure(result.error, result.details) if result.failure?

    render json: yield(result.value), status: status
  end
end
