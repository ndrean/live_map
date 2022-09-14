defmodule LiveMap.DownwindFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveMap.Downwind` context.
  """

  @doc """
  Generate a place.
  """
  def place_fixture(attrs \\ %{}) do
    {:ok, place} =
      attrs
      |> Enum.into(%{
        address: "some address",
        country: "some country",
        latitude: 120.5,
        longitude: 120.5
      })
      |> LiveMap.Downwind.create_place()

    place
  end
end
