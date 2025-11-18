defmodule HackScraperWeb.HackathonLive.FormComponent do
  use HackScraperWeb, :live_component

  alias HackScraper.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="hackathon-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:image]} type="text" label="Image" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="text" label="Location" />

        <noscript class="block p-3 text-sm bg-red-50 rounded border">
          Note: the server expects the dates in UTC. Enable JavaScript to convert them automatically from your local timezone.
        </noscript>

        <div :if={assigns[:date_hint]} class="block p-3 text-sm bg-blue-50 rounded border">
          <span class="font-bold">Date information found:</span> {@date_hint}
        </div>

        <.input field={@form[:start_date]} type="datetime-local" label="Start date" />
        <.input field={@form[:end_date]} type="datetime-local" label="End date" />

        <.input
          field={@form[:series_id]}
          type="select"
          label="Series"
          options={series_opts(@form[:series_id])}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Hackathon</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def series_opts(series_id) do
    [[key: "No Series", value: nil, selected: is_nil(series_id)]] ++
      for ser <- HackScraper.Events.list_series() do
        [key: ser.name, value: ser.id, selected: ser.id == series_id]
      end
  end

  @impl true
  def update(%{hackathon: hackathon} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Events.change_hackathon(hackathon))
     end)}
  end

  @impl true
  def handle_event("validate", %{"hackathon" => hackathon_params}, socket) do
    changeset = Events.change_hackathon(socket.assigns.hackathon, hackathon_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"hackathon" => hackathon_params}, socket) do
    save_hackathon(socket, socket.assigns.action, hackathon_params)
  end

  defp save_hackathon(socket, :edit, hackathon_params) do
    case Events.update_hackathon(socket.assigns.hackathon, hackathon_params) do
      {:ok, hackathon} ->
        notify_parent({:saved, hackathon})

        {:noreply,
         socket
         |> put_flash(:info, "Hackathon updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_hackathon(socket, :new, hackathon_params) do
    case Events.create_hackathon(hackathon_params) do
      {:ok, hackathon} ->
        notify_parent({:saved, hackathon})

        {:noreply,
         socket
         |> put_flash(:info, "Hackathon created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
