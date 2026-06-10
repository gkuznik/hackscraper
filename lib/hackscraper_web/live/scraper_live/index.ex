defmodule HackScraperWeb.ScraperLive.Index do
  use HackScraperWeb, :live_view

  alias HackScraper.Scrapers
  alias HackScraper.Scrapers.Scheduled

  on_mount {HackScraperWeb.LiveAuth, :admin}

  @impl true
  def handle_params(params, _url, socket) do
    {scrapers, meta} =
      Flop.validate_and_run!(Scheduled, params, for: Scheduled, replace_invalid_params: true)

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:scrapers, scrapers, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    scraper = Scrapers.get_scraper!(id)

    socket
    |> assign(:page_title, "Edit Scraper #{scraper.name}")
    |> assign(:scraper, scraper)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Scraper")
    |> assign(:scraper, %Scheduled{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Scrapers")
    |> assign(:scraper, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.ScraperLive.FormComponent, {:saved, scraper}}, socket) do
    {:noreply, stream_insert(socket, :scrapers, scraper)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    scraper = Scrapers.get_scraper!(id)
    {:ok, _} = Scrapers.delete_scraper(scraper)

    {:noreply, stream_delete(socket, :scrapers, scraper)}
  end

  @impl true
  def handle_event("pause", %{"id" => id}, socket) do
    scraper = Scrapers.get_scraper!(id)
    {:ok, scraper} = Scrapers.update_scraper(scraper, %{paused: !scraper.paused})

    {:noreply, stream_insert(socket, :scrapers, scraper, update_only: true)}
  end

  @impl true
  def handle_event("run", %{"id" => id}, socket) do
    scraper = Scrapers.get_scraper!(id)
    {:ok, job} = HackScraper.Worker.Scheduler.schedule_job(scraper)

    {:noreply, redirect(socket, to: ~p"/oban/jobs/#{job.id}")}
  end

  @impl true
  def handle_event("clear-filter", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/scrapers")}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/scrapers?#{params}")}
  end
end
