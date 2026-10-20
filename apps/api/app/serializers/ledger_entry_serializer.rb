# A funder sees spends with the place name, never where the owner was.
class LedgerEntrySerializer
  def initialize(entry, wallet:)
    @entry = entry
    @wallet = wallet
  end

  def as_json(*)
    { id: @entry.id, kind: @entry.kind, amount_cents: @entry.amount_cents, currency: @wallet.currency,
      place_name: @entry.spend? ? @wallet.place.name : nil, created_at: @entry.created_at.iso8601(3) }
  end
end
