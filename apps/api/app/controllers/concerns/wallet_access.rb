# Finds the wallet in the URL among those the user can see (others are a 404,
# so their existence isn't revealed) and checks WalletPolicy for the action.
module WalletAccess
  private

  def wallet
    @wallet ||= Wallet.visible_to(current_user).find(params[:wallet_id] || params[:id])
  end

  def authorize_wallet!(action)
    render_failure(:forbidden) unless WalletPolicy.new(current_user, wallet).public_send(action)
  end
end
