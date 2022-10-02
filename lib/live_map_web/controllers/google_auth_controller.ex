defmodule LiveMapWeb.GoogleAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.User

  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)

    case profile do
      %{email: email} ->
        user = User.new(email)
        user_token = LiveMap.Token.user_generate(user.id)

        conn
        |> put_session(:user_token, user_token)
        |> put_session(:user_id, user.id)
        |> put_session(:profile, profile)
        |> redirect(to: "/welcome")
        |> halt()

      _ ->
        render(conn, "index.html")
    end
  end
end
