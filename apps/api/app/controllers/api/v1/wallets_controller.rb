module Api
  module V1
    class WalletsController < BaseController
      include WalletAccess

      before_action -> { authorize_wallet!(:view?) }, only: :show

      def index
        wallets = Wallet.visible_to(current_user).includes(:place, :owner, :funder).newest_first
        render json: WalletsSerializer.new(wallets, viewer: current_user)
      end

      def show
        render json: WalletDetailSerializer.new(wallet, viewer: current_user)
      end

      def create
        result = ::Wallets::Create.new.call(funder: current_user, attributes: wallet_params)
        render_result(result, status: :created) { |created| CreatedWalletSerializer.new(created, viewer: current_user) }
      end

      private

      def wallet_params
        permitted = params.permit(:kind, :name, :place_id, :currency, :target_cents, :expires_at,
          time_windows: [ :starts_at, :ends_at, :time_zone, { days_of_week: [] } ]).to_h.symbolize_keys
        permitted.merge(time_windows_attributes: permitted.delete(:time_windows) || [])
      end
    end
  end
end
