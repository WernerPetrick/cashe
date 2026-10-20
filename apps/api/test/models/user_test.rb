require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "defaults to the adult role" do
    assert_predicate User.new, :adult?
  end

  test "rejects an unknown role" do
    user = User.new(appwrite_user_id: "x", display_name: "X", role: "admin")

    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "the database enforces a unique appwrite_user_id" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.create!(appwrite_user_id: users(:parent).appwrite_user_id, display_name: "Copy")
    end
  end

  test "the database enforces the role check" do
    assert_raises(ActiveRecord::StatementInvalid) do
      users(:parent).update_column(:role, "admin")
    end
  end
end
