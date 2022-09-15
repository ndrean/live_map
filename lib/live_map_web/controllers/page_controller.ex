defmodule LiveMapWeb.PageController do
  use LiveMapWeb, :controller

  def index(conn, _params) do
    # IO.puts("__________________________PageCTL")
    oauth_google_url = ElixirAuthGoogle.generate_oauth_url(conn)
    oauth_github_url = ElixirAuthGithub.login_url(%{scopes: ["user:email"]})

    render(conn, "index.html",
      oauth_github_url: oauth_github_url,
      oauth_google_url: oauth_google_url
    )
  end
end
