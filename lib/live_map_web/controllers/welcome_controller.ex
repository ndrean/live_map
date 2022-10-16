defmodule LiveMapWeb.WelcomeController do
  use LiveMapWeb, :controller

  def index(conn, p) do
    IO.inspect(p, label: "welcome")
    profile = get_session(conn, :profile)
    user_token = get_session(conn, :user_token)
    conn = conn |> assign(:user_token, user_token)
    render(conn, "welcome.html", profile: profile)
  end
end
