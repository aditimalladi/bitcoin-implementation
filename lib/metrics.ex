defmodule Metrics do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def total_txn(server) do
    GenServer.call(server, {:total_txn})
  end

  def btc_mined(server) do
    GenServer.call(server, {:btc_mined})
  end

  def total_btc_tx(server) do
    GenServer.call(server, {:total_btc_tx})
  end 

  def blockchain_length(server) do
    GenServer.call(server, {:blockchain_length})
  end 

  def tps_data(server) do
    GenServer.call(server, {:tps_data})
  end 

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:total_txn}, _from, state) do
    [{_, num_txn}] = :ets.lookup(:metrics, :num_txn)
    {:reply, num_txn, state}
  end

  def handle_call({:btc_mined}, _from, state) do
    [{_, num_btc}] = :ets.lookup(:metrics, :num_btc)
    {:reply, num_btc, state}
  end

  def handle_call({:total_btc_tx}, _from, state) do
    [{_, num_btc_tx}] = :ets.lookup(:metrics, :num_btc_tx)
    :ets.insert(:metrics, {:num_btc_tx, 0})
    {:reply, num_btc_tx, state}
  end

  def handle_call({:blockchain_length}, _from, state) do
    [{_, blockchain_length}] = :ets.lookup(:metrics, :blockchain_length)
    {:reply, blockchain_length, state}
  end

  def handle_call({:tps_data}, _from, state) do
    [{_, tps_data}] = :ets.lookup(:metrics, :tps_data)
    :ets.insert(:metrics, {:tps_data, 0})
    {:reply, tps_data, state}
  end

end