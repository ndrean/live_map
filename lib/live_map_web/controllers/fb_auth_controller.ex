defmodule LiveMapWeb.FacebookAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.ElixirAuthFacebook
  alias Libraries.ElixirAuthFacebook
  action_fallback LiveMapWeb.LoginErrorController

  def login(conn, params) do
    with {:ok, profile} <- ElixirAuthFacebook.handle_callback(conn, params),
         %{email: email} <- profile do
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> put_session(:origin, "fb_ssr")
      |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: LiveMapWeb.Router.Helpers.welcome_path(conn, :index))
      |> halt()
    end
  end
end
