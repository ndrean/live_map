defmodule DatePicker.DatePickerTest do
  use LiveMapWeb.ConnCase

  import Phoenix.LiveViewTest

  @evt_date %{event_date: ~D[2022-12-01]}
  @invalid %{event_date: nil}

  test "renders form", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    IO.inspect(html, label: "html")
    IO.inspect(view, label: "view")
    assert html =~ ""
  end
end
