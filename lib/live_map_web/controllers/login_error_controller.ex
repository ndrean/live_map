defmodule LiveMapWeb.LoginErrorController do
  use LiveMapWeb, :controller
  require Logger
  # don't "use Phoenix.Controller" if you want to use "Routes" helpers

  def call(conn, {:error, message}) do
    Logger.warning("Got error during login #{inspect(message)}")

    conn
    |> fetch_session()
    |> fetch_flash()
    |> put_flash(:error, inspect(message))
    |> put_view(LiveMapWeb.PageView)
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end
end
