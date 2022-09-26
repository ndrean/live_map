defmodule LiveMapWeb.GoogleAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.User

  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)

    case profile do
      %{email: email} ->
        user = User.new(email)
        user_token = Phoenix.Token.sign(LiveMapWeb.Endpoint, "user token", user.id)

        conn
        |> assign(:user_id, user.id)
        |> assign(:user_token, user_token)
        |> put_session(:user, profile.email)
        |> put_session(:user_id, user.id)
        |> put_view(LiveMapWeb.PageView)
        |> render(:welcome, profile: profile)

      _ ->
        render(conn, "index.html")
    end
  end
end
