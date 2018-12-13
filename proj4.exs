:observer.start()
[numUsers, numTxn] = System.argv

{numUsers, _} = Integer.parse(numUsers)
{numTxn, _} = Integer.parse(numTxn)
# 2 leading zeroes
difficulty = "1fffffff"

Pool.start_link([], name: MyPool)

# FORMAT - {walletaddress - {publicKey, pid}}
data = :ets.new(:data, [:set, :named_table, :public])

# To store metrics to pass to phx
# FORMAT - 
metrics = :ets.new(:metrics, [:set, :named_table, :public])
:ets.insert(:metrics, {:num_txn, 0})
:ets.insert(:metrics, {:num_btc, 0})
:ets.insert(:metrics, {:num_btc_tx, 0})
:ets.insert(:metrics, {:blockchain_length, 0})
:ets.insert(:metrics, {:tps_data, 0})
Metrics.start_link([], [name: MyMetrics])

pid_stash = :ets.new(:pid_stash, [:set, :named_table, :public])

#create Genesis block
genesis_block = %{
  :header => %{
    :version => 1,
    :previous_block => "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => difficulty,   
    :nonce => 0,
  },
  :hash => nil,
  :txn => nil,
  :coinbase_txn => nil
}

{:ok, full_node_pid} = Peer.start_link({:full_node, difficulty}, [name: FullNode])

# creating the network of peers
list_of_users = 
Enum.map(0..numUsers - 1, fn(user)->
  {:ok, pid} = Peer.start_link({:peer, difficulty}, [])
  pid
end)

{:ok, miner_pid} = Peer.start_link({:peer, difficulty}, [])
pids = list_of_users ++ [miner_pid]
:ets.insert(:data, {:pids, pids})

# mine the genesis block
Peer.mine_genesis_block(miner_pid, genesis_block)
:timer.sleep(5000)

# first everyone needs to mine empty blocks
Enum.each(list_of_users, fn(pid)->
  Peer.mint_money(pid)
  :timer.sleep(200)
end)

Enum.each(0..numTxn - 1, fn(txn)->
  user1 = Enum.random(list_of_users)
  user2 = Enum.random(list_of_users)
  [{_, wallet_add_user2}] = :ets.lookup(:pid_stash, user2)
  money_to_send = Enum.random(20..50)
  :timer.sleep(1300)
  Peer.create_txn(user1, {wallet_add_user2, 34})
end)

IO.puts "Waiting for latest blockchain propogation"
:timer.sleep(1300)


miner_state = Peer.get_state(miner_pid)
full_node_state = Peer.get_state(full_node_pid)
full_node_length = length(full_node_state[:blockchain])
blockchain_length = length(miner_state[:blockchain])

IO.puts "Full Node length: #{full_node_length}"
IO.puts "Blockchain length: #{blockchain_length}"
IO.puts "#{numTxn} transactions carried out. Ciao!"



:timer.sleep(100000000)