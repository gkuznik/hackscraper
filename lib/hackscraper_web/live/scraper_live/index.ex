defmodule HackScraperWeb.ScraperLive.Index do
  use HackScraperWeb, :live_view

  alias HackScraper.Worker
  alias HackScraper.Worker.Scraper

  @impl true
  def handle_params(params, _url, socket) do
    {scrapers, meta} =
      Flop.validate_and_run!(Scraper, params, for: Scraper, replace_invalid_params: true)

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:scrapers, scrapers, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    scraper = Worker.get_scraper!(id)

    socket
    |> assign(:page_title, "Edit Scraper " <> scraper.name)
    |> assign(:scraper, scraper)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Scraper")
    |> assign(:scraper, %Scraper{})
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
    scraper = Worker.get_scraper!(id)
    {:ok, _} = Worker.delete_scraper(scraper)

    {:noreply, stream_delete(socket, :scrapers, scraper)}
  end

  @impl true
  def handle_event("pause", %{"id" => id}, socket) do
    scraper = Worker.get_scraper!(id)
    {:ok, scraper} = Worker.update_scraper(scraper, %{paused: !scraper.paused})

    {:noreply, stream_insert(socket, :scrapers, scraper, update_only: true)}
  end

  @impl true
  def handle_event("run", %{"id" => id}, socket) do
    scraper = Worker.get_scraper!(id)
    {:ok, job} = HackScraper.Scraper.Scheduler.schedule_job(scraper)

    {:noreply, push_navigate(socket, to: ~p"/oban/jobs/#{job.id}")}
  end
end
