class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    { id: @user.id, display_name: @user.display_name, role: @user.role }
  end
end
