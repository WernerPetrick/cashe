# Balance = SUM(amount_cents) of a wallet's ledger entries. There is no balance column.
class WalletBalances
  def cents_for(wallet)
    LedgerEntry.where(wallet_id: wallet.id).sum(:amount_cents).to_i
  end

  def for(wallet)
    Money.new(cents_for(wallet), wallet.currency)
  end

  # One query for many wallets: { wallet_id => Money }.
  def for_all(wallets)
    sums = LedgerEntry.where(wallet_id: wallets.map(&:id)).group(:wallet_id).sum(:amount_cents)
    wallets.to_h { |wallet| [ wallet.id, Money.new(sums.fetch(wallet.id, 0).to_i, wallet.currency) ] }
  end
end
