# Stands in for AppwriteAuth::Directory: knows a fixed set of emails.
class FakeDirectory
  attr_reader :lookups

  def initialize(emails = [], unavailable: false)
    @emails = emails
    @unavailable = unavailable
    @lookups = []
  end

  def account_exists?(email)
    raise AppwriteAuth::Unavailable, "down" if @unavailable

    @lookups << email
    @emails.include?(email)
  end
end
