defmodule Pool do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def put_txn(server, txn) do
    GenServer.cast(server, {:put_txn, txn})
  end

  def get_txn(server) do
    GenServer.call(server, {:get_txn})
  end

  # pool of pending txns will be a FIFO lust
  def init() do
    {:ok, []}
  end

  def handle_cast({:put_txn, txn}, state) do
    state = state ++ [txn]
    {:noreply, state}
  end

  def handle_call({:get_txn}, _from, state) do
    if(state == []) do
      {:reply, nil, state}
    else
      [head | tail] = state
      {:reply, head, tail}
    end
  end
end
