defmodule LiveMapWeb.GithubAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.User

  @doc """
  `index/2` handles the callback from GitHub Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, profile} = ElixirAuthGithub.github_auth(code)

    case profile do
      %{email: email} ->
        User.new(email)
    end

    conn
    # if I use "put_view", no need to create "view/guthub_auth_view.ex" + "templates/github_Auth.html.heex"
    # |> put_view(LiveMapWeb.PageView)
    # |> put_session(:profile, profile)
    |> put_session(:user, profile.email)
    |> put_view(LiveMapWeb.PageView)
    |> render(:welcome, profile: profile)
  end
end
