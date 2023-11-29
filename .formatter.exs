[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  inputs: ["*.{ex,exs}", "{config,lib,test,run}/**/*.{ex,exs}", "priv/*/seeds.exs"]
]
