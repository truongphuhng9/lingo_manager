# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias LingoManager.Accounts

# Create default admin user
admin_attrs = %{
  email: "admin@lingo-manager.local",
  password: "admin123456",
  password_confirmation: "admin123456",
  name: "Administrator",
  role: "admin"
}

case Accounts.get_user_by_email(admin_attrs.email) do
  nil ->
    {:ok, admin} = Accounts.register_user(admin_attrs)
    IO.puts("Created admin user: #{admin.email}")

  _user ->
    IO.puts("Admin user already exists")
end
