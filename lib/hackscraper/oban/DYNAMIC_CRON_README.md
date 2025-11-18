# Dynamic Cron Plugin for Oban

An Oban plugin that enables dynamic cron scheduling for jobs. Unlike the standard `Oban.Plugins.Cron` which requires static configuration, this plugin allows you to manage cron schedules dynamically through the database at runtime.

## Features

- **Dynamic Schedules**: Create, update, and delete cron schedules without restarting your application
- **Database-Driven**: All schedules are stored in the database and can be managed through your application
- **Enable/Disable**: Easily enable or disable schedules without deleting them
- **Flexible Cron Expressions**: Supports standard cron expressions and named shortcuts (@daily, @hourly, etc.)
- **Configurable**: Customize check intervals and timezones
- **Safe**: Validates cron expressions and worker modules before saving

## Installation

The plugin is already included in this application. If you need to use it in a new application, ensure you have these dependencies:

```elixir
def deps do
  [
    {:oban, "~> 2.19"},
    {:crontab, "~> 1.1"}  # Included as a transitive dependency of Oban
  ]
end
```

## Database Setup

Run the migration to create the `dynamic_cron_schedules` table:

```bash
mix ecto.migrate
```

## Configuration

Add the plugin to your Oban configuration in `config/config.exs`:

```elixir
config :hackscraper, Oban,
  repo: HackScraper.Repo,
  plugins: [
    # ... other plugins
    {HackScraper.Oban.Plugins.DynamicCron, interval: 60_000, timezone: "Etc/UTC"}
  ],
  queues: [default: 5, scraper: 10]
```

### Configuration Options

- `:interval` - How often to check for schedules to run (in milliseconds). Default: 60_000 (1 minute)
- `:timezone` - Timezone for cron expression evaluation. Default: "Etc/UTC"

## Usage

### Creating a Schedule

```elixir
alias HackScraper.Oban.DynamicCron

# Create a schedule that runs daily
{:ok, schedule} = DynamicCron.create_schedule(%{
  name: "daily_scraper",
  cron_expression: "@daily",
  worker: "HackScraper.Scraper.Devpost",
  args: %{},
  enabled: true
})
```

### Supported Cron Expressions

The plugin supports standard cron expressions and shortcuts:

**Named shortcuts:**
- `@yearly` or `@annually` - Run once a year at midnight on January 1st
- `@monthly` - Run once a month at midnight on the first day
- `@weekly` - Run once a week at midnight on Sunday
- `@daily` or `@midnight` - Run once a day at midnight
- `@hourly` - Run once an hour at the beginning of the hour

**Standard cron format:** `minute hour day month weekday`

Examples:
- `"0 0 * * *"` - Run daily at midnight
- `"*/5 * * * *"` - Run every 5 minutes
- `"0 9 * * 1-5"` - Run weekdays at 9 AM
- `"0 0,12 * * *"` - Run twice a day at midnight and noon

### Managing Schedules

```elixir
# List all schedules
schedules = DynamicCron.list_schedules()

# Get a specific schedule by name
schedule = DynamicCron.get_schedule_by_name("daily_scraper")

# Update a schedule
{:ok, updated} = DynamicCron.update_schedule(schedule, %{
  cron_expression: "@weekly"
})

# Enable/disable a schedule
{:ok, _} = DynamicCron.disable_schedule(schedule)
{:ok, _} = DynamicCron.enable_schedule(schedule)

# Delete a schedule
{:ok, _} = DynamicCron.delete_schedule(schedule)
```

### Creating a Worker

Your worker must implement the `Oban.Worker` behaviour:

```elixir
defmodule HackScraper.Scraper.MyWorker do
  use Oban.Worker, queue: :scraper

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Your job logic here
    IO.inspect(args)
    :ok
  end
end
```

## How It Works

1. The plugin runs as a GenServer that checks the database at regular intervals (configured via `:interval`)
2. For each enabled schedule, it evaluates the cron expression to determine if the job should run
3. If a job should run (based on the cron expression and the last execution time), it enqueues the job to Oban
4. After successfully enqueuing a job, the plugin updates the `last_executed_at` timestamp to prevent duplicate executions

## Example: Adding a Schedule via IEx

```elixir
# Start your application
iex -S mix

# Create a new schedule
alias HackScraper.Oban.DynamicCron

DynamicCron.create_schedule(%{
  name: "hourly_devpost_scraper",
  cron_expression: "@hourly",
  worker: "HackScraper.Scraper.Devpost",
  args: %{},
  enabled: true
})

# The job will now run automatically every hour
```

## Monitoring

The plugin logs when:
- It starts up (showing interval and timezone)
- Jobs are enqueued (showing schedule name and job ID)
- Errors occur (invalid cron expressions, failed job creation, etc.)

Check your application logs for messages like:
```
[info] DynamicCron plugin started with interval: 60000ms, timezone: Etc/UTC
[info] Enqueued job for schedule: hourly_devpost_scraper, job_id: 123
```

## Testing

The plugin includes comprehensive tests. Run them with:

```bash
mix test test/hackscraper/oban/
```

## Limitations

- The plugin checks schedules at a fixed interval. Very short cron intervals (like every second) are not supported
- The minimum recommended check interval is 60 seconds (60_000 milliseconds)
- All schedules are evaluated in the configured timezone

## Comparison with Oban.Plugins.Cron

| Feature | Oban.Plugins.Cron | DynamicCron Plugin |
|---------|-------------------|-------------------|
| Configuration | Static (config files) | Dynamic (database) |
| Restart Required | Yes | No |
| Runtime Management | No | Yes |
| Enable/Disable | No | Yes |
| Per-schedule args | No | Yes |
