require "test_helper"

class ResultTest < ActiveSupport::TestCase
  test "success carries a value" do
    result = Result.success(42)

    assert_predicate result, :success?
    assert_equal 42, result.value
  end

  test "failure carries an error code" do
    result = Result.failure(:unauthorized)

    assert_predicate result, :failure?
    assert_equal :unauthorized, result.error
  end
end
