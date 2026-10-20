# A clock tests control: `clock.current` never moves unless advanced.
class FixedClock
  attr_reader :current

  def initialize(current)
    @current = current
  end

  def advance(seconds)
    @current += seconds
    self
  end
end
