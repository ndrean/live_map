defmodule LiveMapWeb.GoogleAuthController do
  use Phoenix.Controller
  alias LiveMap.User

  def index(conn, %{"code" => code}) do
    with {:ok, token} <- ElixirAuthGoogle.get_token(code, conn),
         {:ok, profile} <- ElixirAuthGoogle.get_user_profile(token.access_token),
         %{email: email} <- profile do
      user = User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> put_session(:origin, "google_ssr")
      |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: LiveMapWeb.Router.Helpers.welcome_path(conn, :index))
      |> halt()
    end
  end
end
