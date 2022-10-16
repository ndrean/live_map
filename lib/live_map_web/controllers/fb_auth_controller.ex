defmodule LiveMapWeb.FacebookAuthController do
  use LiveMapWeb, :controller

  def todo(conn, _, _),
    do:
      conn
      |> tap(fn conn -> IO.inspect(conn) end)
      |> Phoenix.Controller.put_flash(:error, "test")
      |> Phoenix.Controller.redirect(to: "/")
      |> Plug.Conn.halt()

  def index(conn, params) do
    # example with modified termination function: &todo/3
    # {:ok, profile} = ElixirAuthFacebook.handle_callback(conn, params, &todo/3)

    {:ok, profile} = ElixirAuthFacebook.handle_callback(conn, params)

    with %{email: email} <- profile do
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> redirect(to: "/welcome")
      |> halt()
    else
      _ -> render(conn, "index.html")
    end
  end
end

# curl -X GET "https://graph.facebook.com/oauth/access_token?client_id=366589421180047&client_secret=a7f31cd0acd223dd63af686842c3f224&grant_type=client_credentials"
