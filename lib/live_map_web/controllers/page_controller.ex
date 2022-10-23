defmodule LiveMapWeb.PageController do
  use Phoenix.Controller

  def index(conn, _params) do
    oauth_google_url = ElixirAuthGoogle.generate_oauth_url(conn)
    oauth_github_url = ElixirAuthGithub.login_url(%{scopes: ["user:email"]})

    oauth_facebook_url = LiveMap.ElixirAuthFacebook.generate_oauth_url(conn)

    conn
    # |> assign(:app_id, System.get_env("FACEBOOK_APP_ID"))
    |> render("index.html",
      oauth_github_url: oauth_github_url,
      oauth_google_url: oauth_google_url,
      oauth_facebook_url: oauth_facebook_url
    )
  end
end

# %Phoenix.Socket.Broadcast{topic: "presence", event: "presence_diff", payload: %{joins: %{}, leaves: %{"phx-Fx7ZGTCWM7857wek" => %{metas: [%{phx_ref: "Fx7ZGTfg5pPKQwRh", user_id: 1}]}}}}
