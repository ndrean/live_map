defmodule LiveMapWeb.GithubAuthController do
  use LiveMapWeb, :controller
  alias LiveMap.User

  action_fallback LiveMapWeb.LoginErrorController

  @doc """
  `index/2` handles the callback from GitHub Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    with {:ok, profile} <- Libraries.ElixirAuthGithub.github_auth(code),
         %{email: email} <- profile do
      user = User.new(email)
      user_token = LiveMap.Token.user_generate(user.id)

      conn
      |> put_session(:user_token, user_token)
      |> put_session(:user_id, user.id)
      |> put_session(:profile, profile)
      |> put_session(:origin, "github")
      |> put_view(LiveMapWeb.WelcomeView)
      |> redirect(to: Routes.welcome_path(conn, :index))
      |> halt()
    end
  end
end
