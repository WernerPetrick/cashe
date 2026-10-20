# Outcome of a service call: a value on success, an error code on expected failure.
class Result
  attr_reader :value, :error

  def self.success(value = nil)
    new(value: value)
  end

  def self.failure(error)
    new(error: error)
  end

  def initialize(value: nil, error: nil)
    @value = value
    @error = error
    freeze
  end

  def success?
    error.nil?
  end

  def failure?
    !success?
  end
end
