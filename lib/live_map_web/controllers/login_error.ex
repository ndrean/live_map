defmodule LiveMapWeb.LoginError do
  use Phoenix.Controller

  def call(conn, {:error, message}) do
    IO.puts("MyError")

    conn
    |> put_flash(:error, inspect(message))
    |> put_view(LiveMapWeb.PageView)
    |> redirect(to: LiveMapWeb.Router.Helpers.page_path(conn, :index))
    |> halt()

    # |> render(:index)
  end
end
