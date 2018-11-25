defmodule Peer do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get_state(server) do
    GenServer.call(server, {:get_state})
  end

  # miner charactersistic
  def add_block(server, block) do
    GenServer.call(server, {:add_block, block})
  end

  # TODO: replace the hash value of the block after calculating
  def mine_block(server, block) do
    GenServer.cast(server, {:mine_block})
  end

  def init(:peer, difficulty) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    wallet_address = :crypto.hash(:sha, public_key) |> Base.encode16(case: :lower)
    :ets.insert(:data, {wallet_address, %{:pid => self(), :public_key => public_key}})

    {:ok,
     %{
       :bits => difficulty,
       :private_key => private_key,
       :public_key => public_key,
       :blockchain => [],
       :wallet_address => wallet_address
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
       :blockchain => [genesis_block],
       :wallet_address => wallet_address
     }}
  end

  def handle_cast({:add_block, block}, state) do
    verification_block = Utils.verify_block(block)

    if(verification_block) do
      blockchain = state[:blockchain]
      state = Map.replace(state, :blockchain, blockchain ++ [block])
      {:noreply, state}
    end

    {:noreply, state}
  end

  # block - is the block to be mined
  def handle_cast({:mine_block}, state) do
    txn_picked_up = Pool.get_txn(MyPool)

    if(txn_picked_up == nil) do
      {:noreply, state}
    else
      # generate the coinbase txn
      # {from, to, amount, private_key} = data
      # TODO: MAKE REWARD DYNAMIC
      coinbase_txn = Utils.generate_tx({"", state[:wallet_address], 100, state[:private_key]})

      # getting prev block to generate a new block
      prev_block = List.last(state[:blockchain])
      block = Utils.generate_block(txn_picked_up, prev_block)

      # adding the reward also to the block
      block = Map.replace(block, :coinbase_txn, coinbase_txn)
      mined_block_header = Utils.mine_block(block)
      block = Map.replace(block, :header, mined_block_header)
      block = Map.replace(block, :hash, Utils.get_block_header_hash(mined_block_header))

      # add new block to the blockchain
      blockchain = state[:blockchain] ++ [block]
      state = Map.replace(state, :blockchain, blockchain)

      # broadcast the new blockchain
    end

    {:noreply, state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end
end
