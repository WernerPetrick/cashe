# An amount in integer cents in one currency. Never a float.
class Money
  include Comparable

  attr_reader :cents, :currency

  def self.currencies
    Rails.configuration.x.cashe.currencies
  end

  def self.zero(currency)
    new(0, currency)
  end

  def initialize(cents, currency)
    raise ArgumentError, "cents must be an Integer" unless cents.is_a?(Integer)
    raise ArgumentError, "unsupported currency" unless self.class.currencies.include?(currency)

    @cents = cents
    @currency = currency
    freeze
  end

  def +(other)
    Money.new(cents + same_currency(other).cents, currency)
  end

  def -(other)
    Money.new(cents - same_currency(other).cents, currency)
  end

  def -@
    Money.new(-cents, currency)
  end

  def <=>(other)
    cents <=> same_currency(other).cents if other.is_a?(Money)
  end

  def eql?(other)
    other.is_a?(Money) && cents == other.cents && currency == other.currency
  end
  alias == eql?

  def hash
    [ cents, currency ].hash
  end

  def negative? = cents.negative?
  def positive? = cents.positive?
  def zero? = cents.zero?

  def as_json(*)
    { amount_cents: cents, currency: currency }
  end

  def to_s
    format("%s %.2f", currency, cents / 100r)
  end

  private

  def same_currency(other)
    raise ArgumentError, "currency mismatch" unless other.currency == currency

    other
  end
end
