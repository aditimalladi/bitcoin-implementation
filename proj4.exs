:observer.start()
[numUsers, numTxn] = System.argv

{numUsers, _} = Integer.parse(numUsers)
{numTxnn, _} = Integer.parse(numTxn)
difficulty = "1effffff"

Pool.start_link([], name: MyPool)


# FORMAT - {walletaddress - {publicKey, pid}}
data = :ets.new(:data, [:set, :named_table, :public])

#create Genesis block
genesis_block = %{
  :header => %{
    :version => 1,
    :previous_block => "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => "1f0fffff",   # 4 leading zeroes
    :nonce => 0,
  },
  :parent => %{
    :version => 1,
    :previous_block => "0000000000000000000000000000000000000000000000000000000000000001",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => "1f0fffff",   # 4 leading zeroes
    :nonce => 0,
  },
  :hash => nil,
  :txn => nil,
  :coinbase_txn => nil
}

{:ok, miner_pid} = Peer.start_link({:peer, difficulty}, [])
{:ok, user1} = Peer.start_link({:peer, difficulty}, [])
{:ok, user2} = Peer.start_link({:peer, difficulty}, [])
:ets.insert(:data, {:pids, [miner_pid, user1, user2]})

Peer.mine_genesis_block(miner_pid, genesis_block)



mined_block_header = Utils.mine_block(genesis_block[:header])
IO.inspect Utils.get_block_header_hash(mined_block_header)



:timer.sleep(1000000)
