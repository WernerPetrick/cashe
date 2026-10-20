class TimeWindow < ApplicationRecord
  WEEK = (0..6)

  belongs_to :wallet

  validates :days_of_week, presence: true
  validates :starts_at, :time_zone, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at }
  validates :time_zone, inclusion: { in: ->(_) { TZInfo::Timezone.all_identifiers } }
  validate :days_within_week

  def weekly_window
    WeeklyWindow.new(days: days_of_week, starts_at: starts_at.seconds_since_midnight.to_i,
      ends_at: ends_at.seconds_since_midnight.to_i, time_zone: time_zone)
  end

  private

  def days_within_week
    return if Array(days_of_week).all? { |day| WEEK.cover?(day) }

    errors.add(:days_of_week, "must be between 0 (Sunday) and 6 (Saturday)")
  end
end
