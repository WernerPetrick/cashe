# A list of wallets with balances from one query.
class WalletsSerializer
  def initialize(wallets, viewer:, balances: WalletBalances.new)
    @wallets = wallets.to_a
    @viewer = viewer
    @balances = balances
  end

  def as_json(*)
    sums = @balances.for_all(@wallets)
    funded = @balances.funded_cents_for_all(@wallets)
    { wallets: @wallets.map { |wallet| serialize(wallet, sums[wallet.id], funded.fetch(wallet.id, 0)) } }
  end

  private

  def serialize(wallet, balance, funded_cents)
    WalletSerializer.new(wallet, viewer: @viewer, balance: balance, funded_cents: funded_cents).as_json
  end
end
