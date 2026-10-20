# Who may do what with a wallet. A goal's owner is also its funder.
class WalletPolicy
  def initialize(user, wallet)
    @user = user
    @wallet = wallet
  end

  def view? = owner? || funder?
  def deposit? = funder?
  def ping? = owner?
  def spend? = owner?
  def cancel? = funder? && @wallet.gift?

  # Unlock state reveals when the owner was at the place, so only they see it.
  def see_unlock? = owner?

  private

  def owner? = @wallet.owner_id == @user.id
  def funder? = @wallet.funder_id == @user.id
end
