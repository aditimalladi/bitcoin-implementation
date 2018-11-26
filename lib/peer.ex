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
    GenServer.cast(server, {:add_block, block})
  end

  def add_genesis_block(server, block) do
    GenServer.cast(server, {:add_genesis_block, block})
  end

  def mine_block(server) do
    GenServer.cast(server, {:mine_block})
  end

  def mine_genesis_block(server, genesis_block) do
    GenServer.cast(server, {:mine_genesis_block, genesis_block})
  end

  def create_txn(server, data) do
    GenServer.cast(server, {:create_txn, data})
  end

  # mine empty blocks to generate inital capital
  def mint_money(server) do
    GenServer.cast(server, {:mint_money})
  end

  def init({:peer, difficulty}) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    wallet_address = :crypto.hash(:sha, public_key) |> Base.encode16(case: :lower)
    :ets.insert(:data, {wallet_address, %{:pid => self(), :public_key => public_key}})
    :ets.insert(:pid_stash, {self(), wallet_address})

    {:ok,
     %{
       :bits => difficulty,
       :private_key => private_key,
       :public_key => public_key,
       :blockchain => [],
       :wallet_address => wallet_address
     }}
  end

  def handle_cast({:add_block, block}, state) do
    verification_block = Utils.verify_block(block, state[:blockchain])
    if(verification_block == true) do
      # IO.puts "Adding block..."
      blockchain = state[:blockchain]
      state = Map.replace(state, :blockchain, blockchain ++ [block])
      {:noreply, state}
    else
      IO.puts "Block Dropped"
      {:noreply, state}
    end
  end

  def handle_cast({:add_genesis_block, block}, state) do
    # IO.puts "Adding genesis block ...."
    blockchain = state[:blockchain]
    state = Map.replace(state, :blockchain, blockchain ++ [block])
    {:noreply, state}
  end

  def handle_cast({:mine_block}, state) do
    txn_picked_up = Pool.get_txn(MyPool)
    if(txn_picked_up == nil ||  !(Utils.verify_txn(txn_picked_up, state[:blockchain]))) do
      {:noreply, state}
    else
      # generate the coinbase txn
      # sending miner's private key for the coinbase txn
      coinbase_txn = Utils.generate_tx({"", state[:wallet_address], 100, state[:private_key]})

      # getting prev block to generate a new block
      prev_block = List.last(state[:blockchain])
      block = Utils.generate_block(txn_picked_up, prev_block, coinbase_txn, state[:bits])

      # adding the reward also to the block
      mined_block_header = Utils.mine_block(block[:header])
      block = Map.replace(block, :header, mined_block_header)
      block = Map.replace(block, :hash, Utils.get_block_header_hash(mined_block_header))

      # add new block to the blockchain
      blockchain = state[:blockchain] ++ [block]
      state = Map.replace(state, :blockchain, blockchain)

      # broadcast the new block
      Utils.broadcast(block)
      {:noreply, state}
    end
  end

  def handle_cast({:mine_genesis_block, genesis_block}, state) do
    IO.puts "Mining Genesis Block ..."
    coinbase_txn = Utils.generate_tx({"", state[:wallet_address], 100, state[:private_key]})
    genesis_block = Map.replace(genesis_block, :coinbase_txn, coinbase_txn)

    # calc merkle root of the genesis block
    coinbase_hash = Utils.hash_txn_data(coinbase_txn) |> Base.encode16(case: :lower)
    header = genesis_block[:header]
    header = Map.replace(header, :merkle_root, coinbase_hash)
    genesis_block = Map.replace(genesis_block, :header, header)

    mined_block_header = Utils.mine_block(genesis_block[:header])
    hash_mined_block_header = Utils.get_block_header_hash(mined_block_header)
    genesis_block = Map.replace(genesis_block, :hash, hash_mined_block_header)
    genesis_block = Map.replace(genesis_block, :header, mined_block_header)

    blockchain = state[:blockchain] ++ [genesis_block]
    state = Map.replace(state, :blockchain, blockchain)

    # broadcast the new mined genesis block
    Utils.broadcast_genesis(genesis_block)
    allow_work()
    {:noreply, state}
  end

  def handle_cast({:create_txn, data}, state) do
    {to, amount} = data
    tx = Utils.generate_tx({state[:wallet_address], to, amount, state[:private_key]})
    Pool.put_txn(MyPool, tx)
    {:noreply, state}
  end

  def handle_cast({:mint_money}, state) do
    coinbase_txn = Utils.generate_tx({"", state[:wallet_address], 100, state[:private_key]})
    prev_block = List.last(state[:blockchain])  
    block = Utils.generate_block(nil, prev_block, coinbase_txn, state[:bits])
    mined_block_header = Utils.mine_block(block[:header])
    block = Map.replace(block, :header, mined_block_header)
    block = Map.replace(block, :hash, Utils.get_block_header_hash(mined_block_header))

    # add new block to the blockchain
    blockchain = state[:blockchain] ++ [block]
    state = Map.replace(state, :blockchain, blockchain)

    # broadcast the new block
    Utils.broadcast(block)
    {:noreply, state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:mine, state) do
    mine_block(self())
    allow_work()
    {:noreply, state}
  end

  defp allow_work() do
    Process.send_after(self(), :mine, 1000)
  end
end


