defmodule LiveMapWeb.Router do
  use LiveMapWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveMapWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    post "/auth/one_tap", LiveMapWeb.OneTapController, :handle
  end

  scope "/", LiveMapWeb do
    pipe_through :browser

    live("/map", MapLive)
    get "/welcome", WelcomeController, :index
    get "/", PageController, :index

    get "/mail/:token", MailController, :confirm_link, params: "token"
  end

  scope "/auth", LiveMapWeb do
    pipe_through :browser

    get "/google/callback", GoogleAuthController, :index
    get "/github/callback", GithubAuthController, :index
    get "/facebook/callback", FacebookAuthController, :login
    get "/fbk/sdk", FbSdkAuthController, :handle
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveMapWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
