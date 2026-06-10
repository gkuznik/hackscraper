defmodule HackScraperWeb.ScraperLive.FormComponent do
  use HackScraperWeb, :live_component

  alias HackScraper.Scrapers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>

      <.simple_form
        for={@form}
        id="scraper-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:worker]}
          type="select"
          label="Worker"
          options={worker_options()}
          phx-change="set_defaults"
        />
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:schedule]} type="text" label="Schedule" required />
        <.input field={@form[:paused]} type="checkbox" label="Paused" />
        <.input
          field={@form[:series_id]}
          type="select"
          label="Series"
          options={series_opts(@form[:series_id])}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Scraper</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp worker_options do
    HackScraper.Worker.Common.workers() |> Map.keys()
  end

  defp series_opts(series_id) do
    [[key: "No Series", value: nil, selected: is_nil(series_id)]] ++
      for ser <- HackScraper.Events.list_series() do
        [key: ser.name, value: ser.id, selected: ser.id == series_id]
      end
  end

  @impl true
  def update(%{scraper: scraper} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Scrapers.change_scraper(scraper))
     end)}
  end

  @impl true
  def handle_event(
        "set_defaults",
        %{"scheduled" => %{"worker" => worker} = scraper_params},
        socket
      ) do
    IO.inspect(scraper_params)
    changeset = socket.assigns.form.data |> Scrapers.change_scraper(%{"worker" => worker})
    default_url = HackScraper.Worker.Common.worker_url(worker)

    changeset =
      Ecto.Changeset.put_change(changeset, :url, default_url)
      |> Ecto.Changeset.put_change(:name, worker)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("validate", %{"scheduled" => scraper_params}, socket) do
    changeset = Scrapers.change_scraper(socket.assigns.scraper, scraper_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"scheduled" => scraper_params}, socket) do
    save_scraper(socket, socket.assigns.action, scraper_params)
  end

  defp save_scraper(socket, :edit, scraper_params) do
    case Scrapers.update_scraper(socket.assigns.scraper, scraper_params) do
      {:ok, scraper} ->
        notify_parent({:saved, scraper})

        {:noreply,
         socket
         |> put_flash(:info, "Scraper updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_scraper(socket, :new, scraper_params) do
    case Scrapers.create_scraper(scraper_params) do
      {:ok, scraper} ->
        notify_parent({:saved, scraper})

        {:noreply,
         socket
         |> put_flash(:info, "Scraper created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
