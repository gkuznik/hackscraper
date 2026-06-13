defmodule HackScraper.Worker.Dummy do
  def scrape(_args) do
    Process.sleep(1000)
    {:suggestions, []}
  end
end
