defmodule Peer do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get_state(server)do
    GenServer.call(server, {:get_state})
  end

  # miner charactersistic
  def add_block(server, block)do
    GenServer.call(server, {:add_block, block})
  end

  def init(:peer) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    wallet_address = :crypto.hash(:sha, public_key) |> Base.encode16(case: :lower)
    :ets.insert(:data, {wallet_address, %{:pid => self(), :public_key => public_key}})
    {:ok,
     %{
       :bits => difficulty,
       :private_key => private_key,
       :public_key => public_key,
       :blockchain => []
     }}
  end

  def init({:genesis, genesis_block, difficulty}) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    wallet_address = :crypto.hash(:sha, public_key) |> Base.encode16(case: :lower)
    mined_block_header = Utils.mine_block(genesis_block[:header])
    genesis_block = Map.replace(genesis_block, :header, mined_block_header)
    :ets.insert(:data, {wallet_address, %{:pid => self(), :public_key => public_key}})
    {:ok,
     %{
       :bits => difficulty,
       :private_key => private_key,
       :public_key => public_key,
       :blockchain => [genesis_block]
     }}
  end

  def handle_cast({:add_block, block}, state)do
    verification_block = Utils.verify_block(block)
    if(verification_block)do
      blockchain  = state[:blockchain]
      state = Map.replace(state, :blockchain, blockchain ++ [block])
      {:noreply, state}
    end
    {:noreply, state}
  end

  def handle_call({:get_state}, _from, state)do
    {:reply, state, state}
  end

end
