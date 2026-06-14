defmodule HackScraperWeb.HackathonLive.Show do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    current_user = socket.assigns.current_user

    if socket.assigns.live_action == :edit && !current_user do
      deny(socket)
    else
      hackathon = Events.get_hackathon!(id)
      is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

      suggestion =
        if current_user && !is_editor do
          Events.get_suggestion_by_user_and_hackathon(current_user.id, hackathon.id)
        else
          nil
        end

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action, hackathon))
       |> assign(:og_title, hackathon.name)
       |> assign(:og_description, og_description(hackathon.description))
       |> assign(:og_image, og_image(hackathon.image))
       |> assign(:og_url, HackScraperWeb.Endpoint.url() <> ~p"/hackathons/#{hackathon.id}")
       |> assign(:hackathon, hackathon)
       |> assign(:suggestion, suggestion)}
    end
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, _hackathon}}, socket) do
    {:noreply, socket}
  end

  defp page_title(:show, hackathon), do: "Hackathon: " <> hackathon.name
  defp page_title(:edit, hackathon), do: "Edit " <> hackathon.name

  defp og_description(nil), do: ""

  defp og_description(description) do
    if String.length(description) > 200 do
      String.slice(description, 0, 200) <> "..."
    else
      description
    end
  end

  defp og_image(nil) do
    HackScraperWeb.Endpoint.url() <> "/images/logo.png"
  end

  defp og_image(image) do
    cond do
      String.starts_with?(image, ["http://", "https://"]) ->
        image

      String.starts_with?(image, "/") ->
        HackScraperWeb.Endpoint.url() <> image

      true ->
        HackScraperWeb.Endpoint.url() <> "/" <> image
    end
  end
end
