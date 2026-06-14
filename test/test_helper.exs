ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(HackScraper.Repo, :manual)
Req.default_options(plug: {Req.Test, HackScraper})
