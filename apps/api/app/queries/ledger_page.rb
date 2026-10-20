# One page of a wallet's history, newest first, paged by entry id.
class LedgerPage
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 50

  def initialize(wallet, before: nil, limit: nil)
    @wallet = wallet
    @before = Integer(before, exception: false) if before
    @limit = (Integer(limit, exception: false) || DEFAULT_LIMIT).clamp(1, MAX_LIMIT)
  end

  def entries = rows.first(@limit)
  def next_before = rows.size > @limit ? entries.last.id : nil
  def wallet = @wallet

  private

  def rows
    @rows ||= (@before ? base.where(id: ...@before) : base).limit(@limit + 1).to_a
  end

  def base = @wallet.ledger_entries.newest_first
end
