# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HackScraper.Repo.insert!(%HackScraper.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger

admin_mail = System.get_env("ADMIN_MAIL")
admin_pwd = System.get_env("ADMIN_PWD")

if admin_mail && admin_pwd do
  case HackScraper.Accounts.register_user(%{
         email: admin_mail,
         name: "admin",
         password: admin_pwd,
         role: HackScraper.Accounts.roles()[:admin]
       }) do
    {:ok, _user} ->
      Logger.info("Created superuser: #{admin_mail}")

    {:error,
     %{errors: [email: {"has already been taken", [constraint: :unique, constraint_name: _]}]} =
         _changeset} ->
      Logger.info("Superuser already exists: #{admin_mail}")

    {:error, changeset} ->
      Logger.error("Error creating superuser: #{inspect(changeset.errors)}")
  end
else
  Logger.warning("ADMIN_MAIL or ADMIN_PWD environment variable not set")
end
