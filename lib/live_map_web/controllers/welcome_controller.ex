defmodule LiveMapWeb.WelcomeController do
  use LiveMapWeb, :controller
  require Logger
  action_fallback LiveMapWeb.LoginErrorController

  def index(conn, _) do
    profile = get_session(conn, :profile)

    user_token = get_session(conn, :user_token)
    user_id = get_session(conn, :user_id)

    conn
    |> assign(:user_token, user_token)
    |> assign(:user_id, user_id)
    |> render(:index, profile: profile)
  end
end
