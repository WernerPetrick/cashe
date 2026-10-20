module Api
  module V1
    module Wallets
      # The sender cancels a gift nobody has claimed yet.
      class CancellationsController < BaseController
        include WalletAccess

        before_action -> { authorize_wallet!(:cancel?) }

        def create
          render_result(::Gifts::Cancel.new.call(wallet: wallet)) do |cancelled|
            WalletDetailSerializer.new(cancelled, viewer: current_user)
          end
        end
      end
    end
  end
end
