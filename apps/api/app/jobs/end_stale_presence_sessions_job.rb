# Closes presence sessions that stopped pinging. Scheduled in config/recurring.yml.
class EndStalePresenceSessionsJob < ApplicationJob
  queue_as :default

  def perform
    Presence::EndStaleSessions.new.call
  end
end
