import ExUnit.Assertions
import IEx.Helpers
import_if_available(Ecto.Query)
import_if_available(Ecto.Query, only: [from: 2])
import_if_available(Ecto.Changeset)

alias LiveMap.{Event, EventParticipants, Repo}

# ex
defmodule E do
  def all_events() do
    Repo.all(Event)
  end

  def event_id(id) do
    Repo.get(Event, id)
    # |> Repo.preload(:eventParticipants)
  end

  def update(schema, changes) do
    schema
    |> Ecto.Changeset.change(changes)
    |> Repo.update()
  end
end
