module Api
  module V1
    module Wallets
      # Simulated top-up; only the wallet's funder may deposit.
      class DepositsController < BaseController
        include WalletAccess

        before_action -> { authorize_wallet!(:deposit?) }

        def create
          result = ::Ledger::Deposit.new.call(wallet: wallet, amount_cents: params[:amount_cents], key: params[:idempotency_key])
          render_result(result, status: :created) { |entry| LedgerEntrySerializer.new(entry, wallet: wallet) }
        end
      end
    end
  end
end
