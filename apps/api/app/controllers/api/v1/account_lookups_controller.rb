module Api
  module V1
    # Before sign-in, so no JWT. It reveals whether an email has an account, so it's rate-limited per IP.
    class AccountLookupsController < ApplicationController
      rate_limit to: 10, within: 1.minute, by: -> { request.remote_ip }, with: -> { render_failure(:rate_limited) }
      rescue_from AppwriteAuth::Unavailable, with: -> { render_failure(:auth_unavailable) }

      def create
        render_result(::Users::LookupAccount.new.call(email: params[:email])) { |exists| { exists: exists } }
      end
    end
  end
end
