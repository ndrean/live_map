defmodule LiveMapWeb.WelcomeController do
  use Phoenix.Controller
  require Logger

  def index(conn, _) do
    profile = get_session(conn, :profile)

    Logger.warning(inspect(profile))

    user_token = get_session(conn, :user_token)

    conn
    |> assign(:user_token, user_token)
    |> render("index.html", profile: profile)
  end
end
