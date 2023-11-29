defmodule AppHelper do
  def current_app_name do
    {:ok, app} = :application.get_application(__MODULE__)
    app
  end

  def default_repo(app \\ current_app_name()) do
    Application.get_env(app, :ecto_repos)
    |> List.first()
  end
end
