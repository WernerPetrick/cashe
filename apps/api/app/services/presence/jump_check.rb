module Presence
  # Catches impossible jumps between pings without keeping coordinates (ADR 0004).
  # All it remembers is the last ping's distance to the place, with its accuracy
  # and time, briefly cached per person and wallet.
  class JumpCheck
    def initialize(distance: PlaceDistance.new, cache: Rails.cache, config: Rails.configuration.x.cashe)
      @distance = distance
      @cache = cache
      @config = config
    end

    # Records this ping and says whether it moved faster than anyone could since the last one.
    def jumped?(wallet:, user:, ping:, now:)
      key = "presence/last_fix/#{wallet.id}/#{user.id}"
      previous = @cache.read(key)
      current = { distance_m: @distance.call(wallet.place, ping.coordinates), accuracy_m: ping.accuracy_m, at: now.to_f }
      @cache.write(key, current, expires_in: @config.ping_gap_seconds)
      recent?(previous, current) && impossible?(previous, current)
    end

    private

    def recent?(previous, current)
      previous.present? && current[:at] - previous[:at] <= @config.ping_gap_seconds
    end

    # A change in distance to a fixed point is never more than the distance moved.
    def impossible?(previous, current)
      reach = @config.max_speed_mps * (current[:at] - previous[:at])
      slack = previous[:accuracy_m] + current[:accuracy_m]
      (current[:distance_m] - previous[:distance_m]).abs > reach + slack
    end
  end
end
