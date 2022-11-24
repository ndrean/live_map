defmodule LiveMap.ChatCache do
  @moduledoc """
  Cache fo the chat in `:ets`
  """

  import Ex2ms
  use GenServer, restart: :transient
  # can be stopped on normal condition

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save_message(emitter_id, receiver_id, message) do
    :ets.insert(:chat, {Time.utc_now(), emitter_id, receiver_id, message})
    # GenServer.call(__MODULE__, {:save_message, {time, emitter, message}})
  end

  @doc """
  Returns an ordered string "emitter_id-receiver_id".
  The "channel_string" is ordered with the smaller id first to be unique for (emitter, receiver), (receiver, emitter).
  """
  def new_channel(id1, id2) when id1 < id2 do
    key = "#{id1}-#{id2}"
    # channel = LiveMap.Utils.set_channel2(id1, id2)
    :ets.insert(:channels, {key, id1, id2, Time.utc_now()})
    key
  end

  def new_channel(id1, id2) when id1 > id2 do
    key = "#{id2}-#{id1}"
    # channel = LiveMap.Utils.set_channel2(id1, id2)
    :ets.insert(:channels, {key, id2, id1, Time.utc_now()})
    key
  end

  @doc """
  Returns an "ordered" tuple tuple {channel_string, emitter_id, receiver_id, timestamp}. The "channel_string"
  is ordered with the smaller id first to be unique for (emitter, receiver), (receiver, emitter).
  """
  def check_channel(id1, id2) when id1 < id2 do
    # channel = LiveMap.Utils.set_channel2(id1, id2)
    :ets.match_object(:channels, {:"$1", id1, id2, :"$2"})
    |> List.first()
  end

  def check_channel(id1, id2) when id2 < id1 do
    # channel = LiveMap.Utils.set_channel2(id1, id2)
    :ets.match_object(:channels, {:"$1", id2, id1, :"$2"})
    |> List.first()
  end

  @doc """
  Returns a list of "ordered" tuples where the channel string conttains the id.
  The output is [{channel_string, emitter_id, receiver_id},{...}]
  """
  def get_channels(id) do
    q =
      Ex2ms.fun do
        {ch, e, r, _} when e == ^id or r == ^id -> {ch, e, r}
      end

    :ets.select(:channels, q)
  end

  def time_compare(t1, t2) do
    Time.compare(t1, t2) == :lt
  end

  def get_messages_by_emitter(emitter_id) do
    :ets.match_object(:chat, {:"$1", to_string(emitter_id), :"$2", :"$3"})
    |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  end

  def get_messages_by_receiver(receiver_id) do
    :ets.match_object(:chat, {:"$1", :"$2", to_string(receiver_id), :"$3"})
    |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  end

  def get_messages_by_channel(emitter_id, receiver_id) do
    [
      :ets.match_object(:chat, {:"$1", to_string(emitter_id), to_string(receiver_id), :"$2"})
      | :ets.match_object(:chat, {:"$1", to_string(receiver_id), to_string(emitter_id), :"$2"})
    ]
    |> List.flatten()
    |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  end

  def init(_) do
    opts = [:ordered_set, :named_table, :public, read_concurrency: true]
    :ets.new(:chat, opts)
    :ets.new(:channels, opts)
    {:ok, []}
  end
end
