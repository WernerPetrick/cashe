# How long someone has stayed inside a zone, against how long they must stay.
class DwellProgress
  attr_reader :required_seconds

  def initialize(entered_at:, now:, required_seconds:)
    @entered_at = entered_at
    @now = now
    @required_seconds = required_seconds
  end

  def elapsed_seconds
    (@now - @entered_at).floor.clamp(0, required_seconds)
  end

  def complete?
    elapsed_seconds >= required_seconds
  end
end
