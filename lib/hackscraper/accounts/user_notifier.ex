defmodule HackScraper.Accounts.UserNotifier do
  use HackScraperWeb, :verified_routes
  use Oban.Worker, queue: :emails, max_attempts: 3

  import Swoosh.Email
  alias HackScraper.Mailer

  # Delivers the email using the application mailer.
  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"type" => type, "user_id" => user_id, "recipient" => recipient, "url" => url}
      }) do
    user = HackScraper.Accounts.get_user(user_id)

    if !user do
      {:discard, "User not found"}
    else
      {subject, body} = message(type, user, url)

      email =
        new()
        |> to(recipient)
        |> from({"HackScraper", Application.get_env(:hackscraper, HackScraperWeb)[:sender_mail]})
        |> reply_to(
          {"HackScraper", Application.get_env(:hackscraper, HackScraperWeb)[:contact_mail]}
        )
        |> subject(subject)
        |> text_body(body)

      Mailer.deliver(email)
    end
  end

  # Queues a mail to be sent asynchronously via Oban
  defp deliver(type, user, url) do
    HackScraper.Accounts.UserNotifier.new(%{
      type: type,
      user_id: user.id,
      recipient: user.email,
      url: url
    })
    |> Oban.insert()
  end

  def deliver_confirmation_instructions(user, url) do
    deliver("confirm_email", user, url)
  end

  def deliver_reset_password_instructions(user, url) do
    deliver("reset_password", user, url)
  end

  def deliver_update_email_instructions(user, url) do
    deliver("update_email", user, url)
  end

  defp message("confirm_email", user, url) do
    {"Welcome to HackScraper! Please confirm your email address",
     """
     Hi #{user.name},

     Welcome to HackScraper!
     Please confirm your email address by visiting the link below:

     #{url}

     Thank you!

     The HackScraper Team
     #{url(~p"/")}
     """}
  end

  defp message("reset_password", user, url) do
    {"Reset your HackScraper password",
     """
     Hi #{user.name},

     You can reset your password by visiting the link below:

     #{url}

     Happy Hacking!
     """}
  end

  defp message("update_email", user, url) do
    {"Update your HackScraper email",
     """
     Hi #{user.name},

     You can change your email by visiting the link below:

     #{url}

     Happy Hacking!
     """}
  end
end
