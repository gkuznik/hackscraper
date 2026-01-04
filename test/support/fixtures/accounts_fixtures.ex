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

  def user_fixture(attrs \\ %{})

  def user_fixture(%{role: _role} = attrs) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HackScraper.Accounts.register_user_with_role(:admin)

    user
  end

  def user_fixture(attrs) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HackScraper.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, job} = fun.(& &1)
    job.args[:url]
  end
end
