defmodule HackScraper.Oban.DynamicCronSchedule do
  @moduledoc """
  Schema for storing dynamic cron schedules that can be modified at runtime.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "dynamic_cron_schedules" do
    field :name, :string
    field :cron_expression, :string
    field :worker, :string
    field :args, :map, default: %{}
    field :enabled, :boolean, default: true
    field :last_executed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:name, :cron_expression, :worker, :args, :enabled, :last_executed_at])
    |> validate_required([:name, :cron_expression, :worker])
    |> validate_cron_expression()
    |> validate_worker_module()
    |> unique_constraint(:name)
  end

  defp validate_cron_expression(changeset) do
    case get_change(changeset, :cron_expression) do
      nil ->
        changeset

      expression ->
        case Crontab.CronExpression.Parser.parse(expression) do
          {:ok, _} ->
            changeset

          {:error, _} ->
            add_error(changeset, :cron_expression, "invalid cron expression")
        end
    end
  end

  defp validate_worker_module(changeset) do
    case get_change(changeset, :worker) do
      nil ->
        changeset

      worker_string ->
        try do
          module = String.to_existing_atom("Elixir.#{worker_string}")

          if Code.ensure_loaded?(module) and function_exported?(module, :perform, 1) do
            changeset
          else
            add_error(
              changeset,
              :worker,
              "worker module must exist and implement perform/1"
            )
          end
        rescue
          ArgumentError ->
            add_error(changeset, :worker, "worker module does not exist")
        end
    end
  end
end
