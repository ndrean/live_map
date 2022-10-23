defmodule NewEvent.NewEventTest do
  use LiveMapWeb.ConnCase

  import Phoenix.LiveViewTest

  @evt_date %{event_date: ~D[2022-12-01]}
  @invalid %{event_date: nil}

  test "renders form", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert html =~ ""
  end
end
