# Places are shared by everyone; adults may add them.
class PlacePolicy
  def initialize(user)
    @user = user
  end

  def create? = @user.adult?
end
