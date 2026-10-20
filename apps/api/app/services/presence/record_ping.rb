module Presence
  # The unlock engine. A wallet unlocks when the owner is inside the place's
  # geofence, inside an allowed time window, and has stayed for the place's
  # dwell time. Coordinates are used for the check and then discarded.
  class RecordPing
    def initialize(geofence: Geofence.new, clock: Time, config: Rails.configuration.x.cashe)
      @geofence = geofence
      @clock = clock
      @config = config
    end

    def call(wallet:, user:, ping:)
      return Result.failure(:wallet_closed) unless wallet.active?

      wallet.with_lock do
        Result.success(evaluate(Tracker.new(wallet: wallet, user: user, now: @clock.current, config: @config), ping))
      end
    end

    private

    def evaluate(tracker, ping)
      reason = rejection(ping)
      return tracker.reject(reason) if reason

      inside = @geofence.contains?(tracker.place, ping.coordinates)
      tracker.track(Checks.new(inside_zone: inside, in_time_window: tracker.in_window?))
    end

    def rejection(ping)
      return :mock_location if ping.mocked && !@config.allow_mock_locations

      :low_accuracy if ping.accuracy_m > @config.max_accuracy_m
    end
  end
end
