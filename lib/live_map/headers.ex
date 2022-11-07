defmodule LiveMap.Headers do
  @behaviour Plug
  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _p) do
    put_resp_header(conn, "cache-control", "public max-age='31436000'")
  end
end
