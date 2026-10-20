# A list of wallets with balances from one query.
class WalletsSerializer
  def initialize(wallets, viewer:, balances: WalletBalances.new)
    @wallets = wallets.to_a
    @viewer = viewer
    @balances = balances
  end

  def as_json(*)
    sums = @balances.for_all(@wallets)
    { wallets: @wallets.map { |wallet| WalletSerializer.new(wallet, viewer: @viewer, balance: sums[wallet.id]).as_json } }
  end
end
