defmodule LiveMapWeb.GithubAuthController do
  use LiveMapWeb, :controller

  @doc """
  `index/2` handles the callback from GitHub Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, profile} = ElixirAuthGithub.github_auth(code)
    IO.inspect(profile)

    conn
    # if I use "put_view", no need to create "view/guthub_auth_view.ex" + "templates/github_Auth.html.heex"
    # |> put_view(LiveMapWeb.PageView)
    |> put_session(:profile, profile)
    |> put_view(LiveMapWeb.PageView)
    |> render(:welcome, profile: profile)

    # |> Phoenix.LiveView.Helpers.live_render(LiveMapWeb.UserLive,
    # session: %{"user_email" => get_session(conn, profile.email)}
    # )
  end
end
