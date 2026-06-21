defmodule HackScraperWeb.HackathonLive.FormComponent do
  @moduledoc """
  input hackathon or suggestion
  sugg_hint
  date_hint
  """
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
            phx-target={@myself}
            phx-click="delete-suggestion"
            data-confirm="Are you sure you want to delete this suggestion?"
            class="!bg-red-600 hover:!bg-red-700 transition-all duration-200"
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
      >
        <.input field={@form[:url]} type="text" label="Url" required phx-debounce="1000" />

        <div
          :if={@scraping_url}
          class="mt-2 p-3 bg-zinc-50 border border-zinc-200 rounded-lg flex items-center space-x-2 animate-pulse"
        >
          <div class="w-4 h-4 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin">
          </div>
          <span class="text-xs text-zinc-500">Gathering details from the URL ...</span>
        </div>

        <div
          :if={@scraped_data}
          class="mt-3 p-4 bg-gradient-to-r from-violet-50 to-indigo-50 border border-violet-100 rounded-xl shadow-sm"
        >
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2">
            <div class="flex space-x-3">
              <div>
                <h4 class="text-sm font-semibold text-indigo-950">
                  We found details for this hackathon
                </h4>

                <div class="mt-3 flex flex-wrap gap-2 text-xs text-indigo-900/90">
                  <div
                    :for={
                      key <- [
                        :name,
                        :image,
                        :description,
                        :location,
                        :date_hint,
                        :start_date,
                        :end_date
                      ]
                    }
                    :if={Map.get(@scraped_data, key) && Map.get(@scraped_data, key) != ""}
                    class="flex items-center space-x-1.5 max-w-[280px]"
                  >
                    <span class="font-bold text-indigo-950 capitalize">
                      {key |> to_string() |> String.replace("_", " ")}:
                    </span>
                    <span class="truncate" title={Map.get(@scraped_data, key)}>
                      {Map.get(@scraped_data, key)}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <button
              type="button"
              phx-click="autofill"
              phx-target={@myself}
              class="self-start sm:ml-4 px-3 sm:px-5 py-1.5 sm:py-2 bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 text-white text-xs sm:text-sm font-semibold rounded-lg shadow-sm hover:shadow transition-all duration-200 flex items-center space-x-1 shrink-0"
            >
              <span>Autofill</span>
              <.icon name="hero-chevron-right" class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        <div
          :if={@scrape_error}
          class="mt-3 p-3 bg-rose-50 border border-rose-100 rounded-xl flex items-center space-x-2"
        >
          <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-rose-500 shrink-0" />
          <span class="text-xs text-rose-700 font-medium">
            Could not automatically get details from the URL.
          </span>
        </div>

        <.input field={@form[:name]} type="text" label="Name" required />

        <.image_upload_input field={@form[:image]} upload={@uploads.image} target={@myself} />

        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="textarea" rows="1" label="Location" />

        <div class="block p-3 text-sm bg-blue-50 rounded border">
          Note: Date and time is in your local timezone.
        </div>

        <div :if={assigns[:date_hint]} class="block p-3 text-sm bg-blue-50 rounded border">
          <span class="font-bold">Date information found:</span> {@date_hint}
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

  defp series_opts(series_id) do
    [[key: "No Series", value: nil, selected: is_nil(series_id)]] ++
      for ser <- HackScraper.Events.list_series() do
        [key: ser.name, value: ser.id, selected: ser.id == series_id]
      end
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:image, auto_upload: true, accept: ["image/*"])}
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
     |> assign_new(:last_url, fn -> data.url || "" end)
     |> assign_new(:scraping_url, fn -> nil end)
     |> assign_new(:scraped_data, fn -> nil end)
     |> assign_new(:scrape_error, fn -> nil end)
     |> assign_new(:form, fn -> to_form(Events.change_hackathon(data)) end)}
  end

  @impl true
  def handle_event("validate", %{"hackathon" => hackathon_params}, socket) do
    url = hackathon_params["url"] || ""
    url_changed? = url != socket.assigns.last_url

    socket =
      if url_changed? and url != "" and valid_url?(url) do
        socket
        |> assign(last_url: url, scraping_url: url, scraped_data: nil, scrape_error: nil)
        |> cancel_async(:scrape_url)
        |> start_async(:scrape_url, fn ->
          try do
            HackScraper.Worker.Direct.scrape(%{"url" => url})
          rescue
            e -> {:error, e}
          end
        end)
      else
        if url_changed? do
          socket
          |> assign(last_url: url, scraping_url: nil, scraped_data: nil, scrape_error: nil)
        else
          socket
        end
      end

    changeset = Events.change_hackathon(socket.assigns.data, hackathon_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("autofill", _, socket) do
    if suggestion = socket.assigns.scraped_data do
      current_params = socket.assigns.form.params

      updated_params =
        current_params
        |> Map.put("name", suggestion.name || current_params["name"])
        |> Map.put("description", suggestion.description || current_params["description"])
        |> Map.put("image", suggestion.image || current_params["image"])

      changeset = Events.change_hackathon(socket.assigns.data, updated_params)

      {:noreply,
       socket
       |> assign(date_hint: suggestion.date_hint, scraped_data: nil)
       |> assign(form: to_form(changeset, action: :validate))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("delete-suggestion", _, socket) do
    {:ok, _} = Events.delete_suggestion(socket.assigns.suggestion)

    {:noreply,
     socket
     |> assign(:suggestion, nil)
     |> assign(:form, to_form(Events.change_hackathon(socket.assigns.hackathon)))}
  end

  def handle_event("save", %{"hackathon" => hackathon_params}, socket) do
    uploads =
      consume_uploaded_entries(socket, :image, fn %{path: path},
                                                  %{uuid: uuid, client_name: client_name} ->
        filename = "#{uuid}#{Path.extname(client_name)}"
        dest = Path.join(Application.fetch_env!(:hackscraper, :uploads_dir), filename)
        File.cp!(path, dest)
        File.rm!(path)
        {:ok, ~p"/uploads/#{filename}"}
      end)

    hackathon_params =
      if image = List.first(uploads),
        do: Map.put(hackathon_params, "image", image),
        else: hackathon_params

    save_hackathon(socket, socket.assigns.action, hackathon_params)
  end

  @impl true
  def handle_async(:scrape_url, {:ok, {:suggestions, [suggestion]}}, socket) do
    {:noreply,
     socket
     |> assign(scraping_url: nil, scraped_data: suggestion, scrape_error: nil)}
  end

  def handle_async(:scrape_url, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(scraping_url: nil, scraped_data: nil, scrape_error: inspect(reason))}
  end

  def handle_async(:scrape_url, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(
       scraping_url: nil,
       scraped_data: nil,
       scrape_error: "Scraper crashed: #{inspect(reason)}"
     )}
  end

  defp valid_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
        String.contains?(host, ".")

      _ ->
        false
    end
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
