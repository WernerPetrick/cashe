# A wallet as one viewer sees it (owner or funder), with its computed balance.
class WalletSerializer
  def initialize(wallet, viewer:, balance:)
    @wallet = wallet
    @viewer = viewer
    @balance = balance
  end

  def as_json(*)
    identity.merge(money, dates, people)
  end

  private

  def identity
    role = @wallet.owner_id == @viewer.id ? "owner" : "funder"
    { id: @wallet.id, kind: @wallet.kind, name: @wallet.name, status: @wallet.status, role: role,
      place: { id: @wallet.place_id, name: @wallet.place.name } }
  end

  def money
    { currency: @wallet.currency, balance_cents: @balance.cents, target_cents: @wallet.target_cents }
  end

  def dates
    { expires_at: @wallet.expires_at&.iso8601(3), claim_expires_at: @wallet.claim_expires_at&.iso8601(3),
      claimed_at: @wallet.claimed_at&.iso8601(3) }
  end

  # "Claimed by <name>" for the funder; "from <name>" for the recipient.
  def people
    { funder_name: @wallet.funder.display_name, owner_name: @wallet.owner&.display_name }
  end
end
