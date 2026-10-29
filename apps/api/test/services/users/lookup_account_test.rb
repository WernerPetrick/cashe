require "test_helper"

class Users::LookupAccountTest < ActiveSupport::TestCase
  setup do
    @directory = FakeDirectory.new([ "pat@example.com" ])
    @lookup = Users::LookupAccount.new(directory: @directory)
  end

  test "finds an existing account, ignoring case and spaces" do
    result = @lookup.call(email: "  Pat@Example.com ")

    assert result.success?
    assert result.value
    assert_equal [ "pat@example.com" ], @directory.lookups
  end

  test "a new email has no account" do
    assert_equal false, @lookup.call(email: "new@example.com").value
  end

  test "refuses an invalid email without asking Appwrite" do
    assert_equal :invalid_email, @lookup.call(email: "pat@example").error
    assert_equal :invalid_email, @lookup.call(email: nil).error
    assert_empty @directory.lookups
  end
end
