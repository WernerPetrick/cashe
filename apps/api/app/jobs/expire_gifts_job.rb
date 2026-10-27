# Refunds unclaimed and expired gifts (ADR 0002). Scheduled in config/recurring.yml.
class ExpireGiftsJob < ApplicationJob
  queue_as :default

  def perform
    Gifts::ExpireDue.new.call
  end
end
