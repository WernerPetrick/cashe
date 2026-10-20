module Api
  module V1
    # Anyone signed in may claim a gift with its token; guessing is rate-limited.
    class GiftClaimsController < BaseController
      rate_limit to: 10, within: 1.minute, by: -> { rate_limit_key }, with: -> { render_failure(:rate_limited) }

      def create
        render_result(::Gifts::Claim.new.call(user: current_user, token: params[:token])) do |wallet|
          WalletDetailSerializer.new(wallet, viewer: current_user)
        end
      end
    end
  end
end
