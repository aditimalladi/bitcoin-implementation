defmodule Peer do
  use GenServer


  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end


  def 

  def init({:genesis, genesis_block, difficulty}) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    wallet_address = :crypto.hash(:sha, public_key) |> Base.encode16(case: :lower)
    mined_block_header = Utils.mine_block(genesis_block[:header])
    genesis_block = Map.replace(genesis_block, :header, mined_block_header)
    :ets.insert(:data, {wallet_address, public_key})
    {:ok, %{:bits => difficulty, :private_key => private_key, :public_key => public_key, :blockchain => [genesis_block]}}
  end

  # write a new init function for non miner of genesis block
  






end