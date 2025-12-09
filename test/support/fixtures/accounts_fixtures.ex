defmodule HackScraper.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Accounts` context.
  """

  def unique_user_name, do: "user#{System.unique_integer()}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "Hello world!"
  def new_valid_user_password, do: "new valid Password!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_user_name(),
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HackScraper.Accounts.register_user()

    user
  end

  def admin_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HackScraper.Accounts.register_user()

    {:ok, user} =
      HackScraper.Accounts.update_user(user, %{role: HackScraper.Accounts.roles()[:admin]})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
