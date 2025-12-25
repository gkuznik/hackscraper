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
      <div :if={assigns[:sugg_hint]} class="mt-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex justify-between items-center">
          <div>
            <h3 class="text-sm font-semibold text-blue-900 mb-2">Existing Suggestion</h3>
            <p class="text-sm text-blue-700">
              We've loaded your existing suggestion for this hackathon.
            </p>
          </div>
          <.button
            type="button"
            phx-target={@myself}
            phx-click="delete_suggestion"
            data-confirm="Are you sure you want to delete this suggestion?"
            class="!bg-red-600 hover:!bg-red-800 "
          >
            Delete Suggestion
          </.button>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="hackathon-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        phx-hook="DateTimeToUTC"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:url]} type="text" label="Url" required />
        <.input field={@form[:image]} type="text" label="Image" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="textarea" rows="1" label="Location" />

        <noscript class="block p-3 text-sm bg-red-50 rounded border">
          Note: the server expects the dates in UTC. Enable JavaScript to convert them automatically from your local timezone.
        </noscript>

        <div :if={assigns[:date_hint]} class="block p-3 text-sm bg-blue-50 rounded border">
          <span class="font-bold">Date information found:</span> {@date_hint}
        </div>

        <div class="flex">
          <.input
            field={@form[:timezone]}
            type="search"
            label="Timezone"
            list="timezones"
            id="timezone-input"
            required
          />
          <datalist id="timezones">
            <%= for {label, name} <- timezones() do %>
              <option value={name}>
                {label}
              </option>
            <% end %>
          </datalist>
          <.button id="autofill" type="button" phx-hook="AutofillLocale">Autofill</.button>
        </div>
        <.input field={@form[:start_date]} type="datetime-local" label="Start date" required />
        <.input field={@form[:end_date]} type="datetime-local" label="End date" required />

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

  def timezones() do
    utc_now = DateTime.utc_now()

    for tz <- TimeZoneInfo.time_zones(links: :ignore) do
      {:ok, local_time} = DateTime.shift_zone(utc_now, tz)

      {"#{tz |> String.replace("_", " ")} (#{local_time.zone_abbr}): #{Calendar.strftime(local_time, "%H:%M")}",
       tz}
    end
  end

  @impl true
  def update(assigns, socket) do
    suggestion = assigns[:suggestion]

    data =
      if suggestion do
        {id, map} = Map.from_struct(suggestion) |> Map.pop(:hackathon_id)
        map = if id, do: Map.put(map, :id, id), else: map
        struct(HackScraper.Events.Hackathon, map)
      else
        assigns[:hackathon]
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(data: data)
     |> assign_new(:form, fn -> to_form(Events.change_hackathon(data)) end)}
  end

  @impl true
  def handle_event("validate", %{"hackathon" => hackathon_params}, socket) do
    changeset = Events.change_hackathon(socket.assigns.data, hackathon_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"hackathon" => hackathon_params}, socket) do
    save_hackathon(socket, socket.assigns.action, hackathon_params)
  end

  def handle_event("delete_suggestion", _, socket) do
    {:ok, _} = Events.delete_suggestion(socket.assigns.suggestion)

    {:noreply,
     socket
     |> assign(:suggestion, nil)
     |> assign(:form, to_form(Events.change_hackathon(socket.assigns.hackathon)))}
  end

  defp save_hackathon(socket, :edit, hackathon_params) do
    user = socket.assigns.current_user

    if HackScraper.Accounts.can_do?(user, :editor) do
      case Events.update_hackathon(socket.assigns.data, hackathon_params) do
        {:ok, hackathon} ->
          notify_parent({:saved, hackathon})

          {:noreply,
           socket
           |> put_flash(:info, "Hackathon updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      suggestion = socket.assigns.suggestion

      result =
        if suggestion do
          hackathon_params = Map.drop(hackathon_params, ["id", "creator_id", "hackathon_id"])
          Events.update_suggestion(suggestion, hackathon_params)
        else
          hackathon_params
          |> Map.put("creator_id", user.id)
          |> Map.put("hackathon_id", socket.assigns.hackathon.id)
          |> Events.create_suggestion()
        end

      case result do
        {:ok, suggestion} ->
          {:noreply,
           socket
           |> put_flash(:info, "Suggestion submitted successfully")
           |> redirect(to: ~p"/suggestions/#{suggestion}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp save_hackathon(socket, :new, hackathon_params) do
    user = socket.assigns.current_user

    if HackScraper.Accounts.can_do?(user, :editor) do
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
    else
      hackathon_params
      |> Map.put("creator_id", user.id)
      |> Map.put("hackathon_id", socket.assigns.hackathon.id)
      |> Events.create_suggestion()
      |> case do
        {:ok, suggestion} ->
          {:noreply,
           socket
           |> put_flash(:info, "Suggestion submitted successfully")
           |> redirect(to: ~p"/suggestions/#{suggestion}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
