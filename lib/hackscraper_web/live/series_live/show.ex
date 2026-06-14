defmodule HackScraperWeb.SeriesLive.Show do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    current_user = socket.assigns.current_user
    is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

    if socket.assigns.live_action == :edit && !is_editor do
      deny(socket)
    else
      series = Events.get_series!(id) |> HackScraper.Repo.preload(:hackathons)

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action, series))
       |> assign(:og_title, series.name)
       |> assign(:og_description, og_description(series.description))
       |> assign(:og_image, og_image(series.image))
       |> assign(:og_url, HackScraperWeb.Endpoint.url() <> ~p"/series/#{series.id}")
       |> assign(:series, series)
       |> assign(:is_editor, is_editor)}
    end
  end

  defp page_title(:show, series), do: "Series: " <> series.name
  defp page_title(:edit, series), do: "Edit " <> series.name

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
