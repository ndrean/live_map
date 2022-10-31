defmodule LiveMapWeb.PageController do
  use LiveMapWeb, :controller
  alias Libraries.{ElixirAuthFacebook, ElixirAuthGoogle}
  action_fallback LiveMapWeb.LoginErrorController

  def index(conn, _params) do
    with oauth_google_url <- ElixirAuthGoogle.generate_oauth_url(conn),
         oauth_github_url <- Libraries.ElixirAuthGithub.login_url(%{scopes: ["user:email"]}),
         oauth_facebook_url <- ElixirAuthFacebook.generate_oauth_url(conn) do
      conn
      |> assign(:app_id, System.get_env("FACEBOOK_APP_ID"))
      |> render("index.html",
        oauth_github_url: oauth_github_url,
        oauth_google_url: oauth_google_url,
        oauth_facebook_url: oauth_facebook_url
      )
    end
  end
end

# %Phoenix.Socket.Broadcast{topic: "presence", event: "presence_diff", payload: %{joins: %{}, leaves: %{"phx-Fx7ZGTCWM7857wek" => %{metas: [%{phx_ref: "Fx7ZGTfg5pPKQwRh", user_id: 1}]}}}}
