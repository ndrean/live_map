defmodule LiveMapWeb.LoginErrorController do
  use LiveMapWeb, :controller
  # don't "use Phoenix.Controller" if you want to use "Routes" helpers

  def call(conn, {:error, message}) do
    IO.puts("MyError")

    conn
    |> fetch_session()
    |> fetch_flash()
    |> put_flash(:error, inspect(message))
    |> put_view(LiveMapWeb.PageView)
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end
end
