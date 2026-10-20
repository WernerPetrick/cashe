module Api
  module V1
    module Wallets
      class LedgerEntriesController < BaseController
        include WalletAccess

        before_action -> { authorize_wallet!(:view?) }

        def index
          render json: LedgerPageSerializer.new(LedgerPage.new(wallet, before: params[:before], limit: params[:limit]))
        end
      end
    end
  end
end
