defmodule Test2 do
  use Phoenix.Component

  def display(assigns) do
    if assigns.place,
      do: ~H"""
        <p><%= if @place, do: @place["distance"], else: 0%></p>
      """,
      else: ~H"""
      """
  end
end
