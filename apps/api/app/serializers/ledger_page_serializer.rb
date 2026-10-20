class LedgerPageSerializer
  def initialize(page)
    @page = page
  end

  def as_json(*)
    entries = @page.entries.map { |entry| LedgerEntrySerializer.new(entry, wallet: @page.wallet).as_json }
    { entries: entries, next_before: @page.next_before }
  end
end
