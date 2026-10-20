# One wallet with its rules and recent history. Unlock state goes to the owner only.
class WalletDetailSerializer
  RECENT_ENTRIES = 10

  def initialize(wallet, viewer:, balances: WalletBalances.new, clock: Time)
    @wallet = wallet
    @viewer = viewer
    @balances = balances
    @clock = clock
  end

  def as_json(*)
    summary.merge(place: PlaceSerializer.new(@wallet.place).as_json, time_windows: time_windows,
      recent_entries: recent_entries, unlocked_until: unlocked_until)
  end

  private

  def summary
    WalletSerializer.new(@wallet, viewer: @viewer, balance: @balances.for(@wallet)).as_json
  end

  def time_windows
    @wallet.time_windows.map { |window| TimeWindowSerializer.new(window).as_json }
  end

  def recent_entries
    @wallet.ledger_entries.newest_first.limit(RECENT_ENTRIES).map do |entry|
      LedgerEntrySerializer.new(entry, wallet: @wallet).as_json
    end
  end

  def unlocked_until
    return unless WalletPolicy.new(@viewer, @wallet).see_unlock?

    @wallet.unlocks.active_at(@clock.current).maximum(:unlocked_until)&.iso8601(3)
  end
end
