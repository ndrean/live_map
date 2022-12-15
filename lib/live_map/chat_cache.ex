defmodule LiveMap.ChatCache do
  @moduledoc """
  Init the ETS "chat" and periodic cleanup of "old" messages
  """
  alias LiveMap.Cache

  @delay Application.compile_env(:live_map, :reset_time, 1)
  import Ex2ms, only: [fun: 1]
  require Logger
  use GenServer, restart: :transient
  # can be stopped on normal condition

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save_message(current, emitter_id, receiver_id, message) do
    GenServer.call(__MODULE__, {:save_message, {current, emitter_id, receiver_id, message}})
  end

  def init(_) do
    opts = [:ordered_set, :named_table, :public, read_concurrency: true]
    :ets.new(:chat, opts)
    :ets.new(:channels, opts)
    Process.send_after(__MODULE__, :clean_chat, :timer.minutes(@delay))
    {:ok, []}
  end

  def handle_call({:save_message, {current, emitter_id, receiver_id, message}}, _from, state) do
    Cache.save_message(current, emitter_id, receiver_id, message)
    {:reply, :ok, state}
  end

  def handle_info(:clean_chat, state) do
    Logger.info("Cleaning ETS:CHAT - #{System.os_time(:second)}")
    Cache.clean_chat(@delay)
    Process.send_after(__MODULE__, :clean_chat, :timer.minutes(@delay))
    {:noreply, state}
  end
end

##############################################

defmodule LiveMap.Cache do
  @moduledoc """
  Interface for ETS functions
  """
  import Ex2ms, only: [fun: 1]

  def save_message(current, emitter_id, receiver_id, message) do
    :ets.insert(:chat, {System.os_time(:second), current, emitter_id, receiver_id, message})
  end

  def time_compare(t1, t2), do: t1 < t2

  # def get_messages_by_receiver(receiver_id) do
  #   :ets.match_object(:chat, {:"$1", :"$2", :"$3", to_string(receiver_id), :"$4"})
  #   |> Enum.sort_by(fn {t, _, _, _, _} -> t end, &time_compare/2)
  # end

  def get_messages_by_channel(emitter_id, receiver_id) do
    ve = to_string(emitter_id)
    vr = to_string(receiver_id)

    ms =
      fun do
        {t, u, e, r, m} when (e == ^ve and r == ^vr) or (e == ^vr and r == ^ve) -> {t, u, e, r, m}
      end

    :ets.select(:chat, ms)
    |> Enum.sort_by(fn {t, _, _, _, _} -> t end, &time_compare/2)
  end

  def clean_chat(delay) do
    some_time_ago = System.os_time(:second) - delay * 60

    ms =
      Ex2ms.fun do
        {t, _e, _u, _r, _m} when t < ^some_time_ago -> true
      end

    :ets.select_delete(:chat, ms)
  end
end
