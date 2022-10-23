defmodule LiveMapWeb.FbSdkAuthController do
  use Phoenix.Controller
  require Logger

  defp into_atoms(strings) do
    for {k, v} <- strings, into: %{}, do: {String.to_atom(k), v}
  end

  defp into_deep(params, key) do
    params
    |> into_atoms()
    |> Map.update!(key, fn pic ->
      pic
      |> Jason.decode!()
      |> into_atoms()
    end)
  end

  def handle(conn, params) do
    profile = into_deep(params, :picture)

    with %{email: email} <- profile do
      user = LiveMap.User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> fetch_session()
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:origin, "fb_sdk")
      |> put_session(:profile, profile)
      |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: LiveMapWeb.Router.Helpers.welcome_path(conn, :index))
      |> halt()
    end
  end
end
