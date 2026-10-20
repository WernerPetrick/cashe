# What a presence ping concluded, in the shape the API returns.
PingOutcome = Data.define(:status, :inside_zone, :in_time_window, :dwell_progress_seconds,
  :dwell_required_seconds, :unlocked_until, :reason) do
  def self.build(status, **fields)
    new(status: status, inside_zone: nil, in_time_window: nil, dwell_progress_seconds: 0,
      dwell_required_seconds: nil, unlocked_until: nil, reason: nil, **fields)
  end

  def as_json(*)
    to_h.merge(unlocked_until: unlocked_until&.iso8601(3)).as_json
  end
end
