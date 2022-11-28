defmodule LiveMap.ChatCache do
  @moduledoc """
  Cache fo the chat in `:ets`
  """

  @delay 10
  import Ex2ms, only: [fun: 1]
  require Logger
  use GenServer, restart: :transient
  # can be stopped on normal condition

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save_message(current, emitter_id, receiver_id, message) do
    # :ets.insert(:chat, {Time.utc_now(), current, emitter_id, receiver_id, message})
    :ets.insert(:chat, {System.os_time(:second), current, emitter_id, receiver_id, message})
  end

  @doc """
  Returns an ordered string "emitter_id-receiver_id".
  The "channel_string" is ordered with the smaller id first to be unique for (emitter, receiver), (receiver, emitter).
  """
  def new_channel(id1, id2) when id1 < id2 do
    key = "#{id1}-#{id2}"
    :ets.insert(:channels, {key, id1, id2, Time.utc_now()})
    key
  end

  def new_channel(id1, id2) when id1 > id2 do
    key = "#{id2}-#{id1}"
    :ets.insert(:channels, {key, id2, id1, Time.utc_now()})
    key
  end

  @doc """
  Returns an "ordered" tuple tuple {channel_string, emitter_id, receiver_id, timestamp}. The "channel_string"
  is ordered with the smaller id first to be unique for (emitter, receiver), (receiver, emitter).
  """
  def check_channel(id1, id2) when id1 < id2 do
    :ets.match_object(:channels, {:"$1", id1, id2, :"$2"})
    |> List.first()
  end

  def check_channel(id1, id2) when id2 < id1 do
    :ets.match_object(:channels, {:"$1", id2, id1, :"$2"})
    |> List.first()
  end

  def rm_channel(ch), do: :ets.delete(:channels, ch)

  @doc """
  Returns a list of "ordered" tuples where the channel string conttains the id.
  The output is [{channel_string, emitter_id, receiver_id},{...}]
  """
  def get_channels(id) do
    q =
      Ex2ms.fun do
        {ch, e, r, _} when e == ^id or r == ^id ->
          {ch, e, r}
      end

    :ets.select(:channels, q)
  end

  def time_compare(t1, t2) do
    # Time.compare(t1, t2) == :lt
    t1 < t2
  end

  def get_messages_by_emitter(emitter_id) do
    :ets.match_object(:chat, {:"$1", :"$2", to_string(emitter_id), :"$3", :"$4"})
    |> Enum.sort_by(fn {t, _, _, _, _} -> t end, &time_compare/2)
  end

  def get_messages_by_receiver(receiver_id) do
    :ets.match_object(:chat, {:"$1", :"$2", :"$3", to_string(receiver_id), :"$4"})
    |> Enum.sort_by(fn {t, _, _, _, _} -> t end, &time_compare/2)
  end

  def get_messages_by_channel(emitter_id, receiver_id) do
    ve = to_string(emitter_id)
    vr = to_string(receiver_id)

    q =
      Ex2ms.fun do
        {t, u, e, r, m} when (e == ^ve and r == ^vr) or (e == ^vr and r == ^ve) -> {t, u, e, r, m}
      end

    :ets.select(:chat, q)
    |> Enum.sort_by(fn {t, _, _, _, _} -> t end, &time_compare/2)
  end

  # def bis(emitter_id, receiver_id) do
  #   [
  #     :ets.match_object(:chat, {:"$1", to_string(emitter_id), to_string(receiver_id), :"$2"})
  #     | :ets.match_object(:chat, {:"$1", to_string(receiver_id), to_string(emitter_id), :"$2"})
  #   ]
  #   |> List.flatten()
  #   |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  # end

  def init(_) do
    opts = [:ordered_set, :named_table, :public, read_concurrency: true]
    :ets.new(:chat, opts)
    :ets.new(:channels, opts)
    Process.send_after(__MODULE__, :clean_chat, :timer.minutes(@delay))
    {:ok, []}
  end

  def handle_info(:clean_chat, state) do
    Logger.info("Cleaning ETS:CHAT")

    some_time_ago = System.os_time(:second) - @delay * 60

    q =
      Ex2ms.fun do
        {t, _e, _u, _r, _m} when t < ^some_time_ago -> true
      end

    :ets.select_delete(:chat, q)
    Process.send_after(__MODULE__, :clean_chat, :timer.minutes(@delay))
    {:noreply, state}
  end
end
