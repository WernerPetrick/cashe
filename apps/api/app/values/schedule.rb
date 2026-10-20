# When a wallet may unlock: any time if it has no windows, otherwise inside one of them.
class Schedule
  def initialize(windows)
    @windows = windows
  end

  def open_at?(time)
    @windows.empty? || @windows.any? { |window| window.include?(time) }
  end
end
