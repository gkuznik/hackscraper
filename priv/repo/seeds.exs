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
  with {:ok, user} <-
         HackScraper.Accounts.register_user(%{
           name: "admin",
           email: admin_mail,
           password: admin_pwd
         }),
       {:ok, _user} <-
         HackScraper.Accounts.update_user(user, %{role: HackScraper.Accounts.roles()[:admin]}) do
    Logger.info("Created superuser: #{admin_mail}")
  else
    {:error, %{errors: [name: {"has already been taken", _}] ++ _}} ->
      Logger.info("User admin already exists")

    {:error, %{errors: errors}} ->
      Logger.error("Error creating superuser: #{inspect(errors)}")
  end
else
  Logger.warning("ADMIN_MAIL or ADMIN_PWD environment variable not set")
end
