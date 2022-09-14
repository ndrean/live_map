defmodule LiveMap.DownwindTest do
  use LiveMap.DataCase

  alias LiveMap.Downwind

  describe "places" do
    alias LiveMap.Downwind.Place

    import LiveMap.DownwindFixtures

    @invalid_attrs %{address: nil, country: nil, latitude: nil, longitude: nil}

    test "list_places/0 returns all places" do
      place = place_fixture()
      assert Downwind.list_places() == [place]
    end

    test "get_place!/1 returns the place with given id" do
      place = place_fixture()
      assert Downwind.get_place!(place.id) == place
    end

    test "create_place/1 with valid data creates a place" do
      valid_attrs = %{address: "some address", country: "some country", latitude: 120.5, longitude: 120.5}

      assert {:ok, %Place{} = place} = Downwind.create_place(valid_attrs)
      assert place.address == "some address"
      assert place.country == "some country"
      assert place.latitude == 120.5
      assert place.longitude == 120.5
    end

    test "create_place/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Downwind.create_place(@invalid_attrs)
    end

    test "update_place/2 with valid data updates the place" do
      place = place_fixture()
      update_attrs = %{address: "some updated address", country: "some updated country", latitude: 456.7, longitude: 456.7}

      assert {:ok, %Place{} = place} = Downwind.update_place(place, update_attrs)
      assert place.address == "some updated address"
      assert place.country == "some updated country"
      assert place.latitude == 456.7
      assert place.longitude == 456.7
    end

    test "update_place/2 with invalid data returns error changeset" do
      place = place_fixture()
      assert {:error, %Ecto.Changeset{}} = Downwind.update_place(place, @invalid_attrs)
      assert place == Downwind.get_place!(place.id)
    end

    test "delete_place/1 deletes the place" do
      place = place_fixture()
      assert {:ok, %Place{}} = Downwind.delete_place(place)
      assert_raise Ecto.NoResultsError, fn -> Downwind.get_place!(place.id) end
    end

    test "change_place/1 returns a place changeset" do
      place = place_fixture()
      assert %Ecto.Changeset{} = Downwind.change_place(place)
    end
  end
end
