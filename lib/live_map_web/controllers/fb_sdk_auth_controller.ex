defmodule LiveMapWeb.FbSdkAuthController do
  use LiveMapWeb, :controller
  require Logger
  alias Libraries.ElixirSdkFacebook

  action_fallback LiveMapWeb.LoginErrorController

  def handler(conn, params) do
    with profile <- ElixirSdkFacebook.parse(params),
         %{email: email} <- profile do
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> fetch_session()
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:origin, "fb_sdk")
      |> put_session(:profile, profile)
      |> redirect(to: Routes.welcome_path(conn, :index))
      |> halt()
    end
  end
end
