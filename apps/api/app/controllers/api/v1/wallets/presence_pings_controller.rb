module Api
  module V1
    module Wallets
      # The unlock screen reports location every 10–15 s; only the owner may ping.
      class PresencePingsController < BaseController
        include WalletAccess

        before_action -> { authorize_wallet!(:ping?) }
        rate_limit to: 12, within: 1.minute, by: -> { rate_limit_key }, with: -> { render_failure(:rate_limited) }

        def create
          ping = PresencePing.from_params(params)
          return render_failure(:invalid_ping) unless ping

          render_result(::Presence::RecordPing.new.call(wallet: wallet, user: current_user, ping: ping)) { |outcome| outcome }
        end
      end
    end
  end
end
