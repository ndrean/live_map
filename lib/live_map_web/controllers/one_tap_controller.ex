defmodule LiveMapWeb.OneTapController do
  use Phoenix.Controller

  def handle(conn, %{"credential" => jwt}) do
    with {:ok, profile} <- LiveMap.GoogleCerts.verified_identity(jwt) do
      # one can use JOSE.JWT.peek_payload(credential)

      %{email: email, name: _name, google_id: _sub, picture: _pic} = profile
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> fetch_session()
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: LiveMapWeb.Router.Helpers.welcome_path(conn, :index))
      |> halt()
    end
  end
end
