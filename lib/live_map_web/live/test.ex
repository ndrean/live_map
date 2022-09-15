defmodule Test do
  use Phoenix.Component

  def display(assigns) do
    IO.inspect(assigns.place, label: "TEST=============================================")

    case assigns.place do
      nil ->
        ~H"""
        <p>nada</p>
        """

      %{"coords" => []} ->
        ~H"""
        <p>no coords</p>
        """

      %{"coords" => coords} ->
        IO.inspect(coords, label: "COOOOOOOOOOOOORDS")

        ~H"""
        <p>ok</p>
        """
    end
  end
end
