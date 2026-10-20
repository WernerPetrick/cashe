# Runs a query without writing its SQL to the log. For queries that contain a
# person's coordinates, which must never be logged (privacy rules).
module QuietSql
  private

  def without_sql_log(&)
    logger = ActiveRecord::Base.logger
    logger ? logger.silence(&) : yield
  end
end
