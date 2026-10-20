module AppwriteAuth
  # Who Appwrite says a token belongs to. Only what Cashe needs: no email.
  Identity = Data.define(:appwrite_user_id, :name) do
    def display_name
      name.presence || "Cashe user"
    end
  end
end
