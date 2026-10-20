require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "holds integer cents in an allowed currency" do
    money = Money.new(1050, "ZAR")

    assert_equal 1050, money.cents
    assert_equal "ZAR", money.currency
  end

  test "rejects floats" do
    assert_raises(ArgumentError) { Money.new(10.5, "ZAR") }
  end

  test "rejects a currency outside the allow-list" do
    assert_raises(ArgumentError) { Money.new(100, "BTC") }
  end

  test "adds and subtracts in the same currency" do
    assert_equal Money.new(700, "USD"), Money.new(1000, "USD") - Money.new(300, "USD")
    assert_equal Money.new(1300, "USD"), Money.new(1000, "USD") + Money.new(300, "USD")
  end

  test "refuses to mix currencies" do
    assert_raises(ArgumentError) { Money.new(100, "USD") + Money.new(100, "ZAR") }
  end

  test "knows its sign and negates" do
    assert_predicate Money.new(-1, "USD"), :negative?
    assert_predicate Money.new(5, "USD"), :positive?
    assert_predicate Money.zero("USD"), :zero?
    assert_equal Money.new(-5, "USD"), -Money.new(5, "USD")
  end

  test "compares amounts" do
    assert_operator Money.new(300, "USD"), :<, Money.new(1000, "USD")
  end

  test "serialises as cents and currency" do
    assert_equal({ amount_cents: 300, currency: "USD" }, Money.new(300, "USD").as_json)
  end
end
