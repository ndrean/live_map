defmodule LiveMapWeb.OneTapController do
  use LiveMapWeb, :controller
  action_fallback LiveMapWeb.LoginErrorController
  require Logger

  def handle(conn, %{"credential" => jwt, "g_csrf_token" => g_csrf_token}) do
    with {:ok, profile} <- Libraries.ElixirGoogleCerts.verified_identity(conn, jwt, g_csrf_token) do
      %{email: email, name: _name, google_id: _sub, picture: _pic} = profile
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> fetch_session()
      |> fetch_flash()
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> put_session(:origin, "google_sdk")
      # |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: Routes.welcome_path(conn, :index))
      |> halt()
    end
  end
end
