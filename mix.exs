defmodule LiveMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_map,
      version: "0.1.0",
      elixir: "~> 1.14.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveMap.Application, []},
      extra_applications: [:logger, :runtime_tools]
      # included_applications: [:mnesia]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # {:phoenix, "~> 1.6.15"},
      {:phoenix, "~> 1.7.0-rc.0", override: true},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:ecto, "~> 3.8"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:phoenix_swoosh, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},
      # {:elixir_auth_google, "~> 1.6.3"},
      # {:elixir_auth_github, "~> 1.6.1"},
      {:geo, "~> 3.4"},
      {:geo_postgis, "~> 3.4"},
      {:timex, "~> 3.7"},
      {:httpoison, "~> 1.8"},
      {:jose, "~> 1.11"},
      {:joken, "~> 2.5"},
      {:ex2ms, "~> 1.6"},
      {:uuid, "~> 1.1"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:faker, "~> 0.17", only: [:dev, :test]},
      # {:flame_on, "~> 0.5.2", only: :dev},
      {:ecto_erd, "~> 0.5.0", only: :dev},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:sobelow, "~> 0.11.1", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      # , "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end

nil
