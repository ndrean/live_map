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
        user = User.new(email)
        user_token = LiveMap.Token.user_generate(user.id)

        conn
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
