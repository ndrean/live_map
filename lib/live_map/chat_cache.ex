defmodule LiveMap.ChatCache do
  @moduledoc """
  Cache fo the chat in `:ets`
  """

  use GenServer, restart: :transient
  # can be stopped on normal condition

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def save_message(emitter_id, receiver_id, message) do
    :ets.insert(:chat, {Time.utc_now(), emitter_id, receiver_id, message})
    # GenServer.call(__MODULE__, {:save_message, {time, emitter, message}})
  end

  def time_compare(t1, t2) do
    Time.compare(t1, t2) == :lt
  end

  def get_messages_by_emitter(emitter_id) do
    :ets.match_object(:chat, {:"$1", emitter_id, :"$2", :"$3"})
    |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  end

  def get_messages_by_receiver(receiver_id) do
    :ets.match_object(:chat, {:"$1", :"$2", receiver_id, :"$3"})
    |> Enum.sort_by(fn {t, _, _, _} -> t end, &time_compare/2)
  end

  def init(_) do
    opts = [:ordered_set, :named_table, :public, read_concurrency: true]
    :ets.new(:chat, opts)
    {:ok, []}
  end

  # def handle_call({:save_message, {time, emitter, message}}, _from, state) do
  #   true = :ets.insert(:chat, {time, emitter, message})
  #   {:reply, :ok, state}
  # end
end
