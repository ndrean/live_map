defmodule LiveMapWeb.GoogleAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.User

  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)

    case profile do
      %{email: email} ->
        User.new(email)
    end

    conn
    |> put_session(:user, profile.email)
    |> put_view(LiveMapWeb.PageView)
    |> render(:welcome, profile: profile)
  end
end
