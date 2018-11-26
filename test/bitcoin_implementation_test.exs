defmodule BitcoinImplementationTest do
  use ExUnit.Case
  doctest BitcoinImplementation

  test "Test - Mining Genesis Block" do
    genesis_block = %{
      :header => %{
        :version => 1,
        :previous_block => "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
        :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
        :timestamp => 1231006505,
        :bits => "1fffffff",   # 4 leading zeroes
        :nonce => 0,
      },
      :parent => %{
        :version => 1,
        :previous_block => "0000000000000000000000000000000000000000000000000000000000000001",
        :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
        :timestamp => 1231006505,
        :bits => "1fffffff",   # 4 leading zeroes
        :nonce => 0,
      },
      :hash => nil,
      :txn => nil,
      :coinbase_txn => nil
    }

    check_header = %{
      bits: "1fffffff",
      merkle_root: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
      nonce: 70,
      previous_block: "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
      timestamp: 1231006505,
      version: 1
    }

    IO.inspect Utils.mine_block(genesis_block[:header])
    assert Utils.mine_block(genesis_block[:header]) == check_header
  end



  test "Transaction" do
    Pool.start_link([], name: MyPool)
    data = :ets.new(:data, [:set, :named_table, :public])
    pid_stash = :ets.new(:pid_stash, [:set, :named_table, :public])
    numUsers = 2
    numTxn = 1
    difficulty = "1fffffff"

    genesis_block = %{
      :header => %{
        :version => 1,
        :previous_block => "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
        :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
        :timestamp => 1231006505,
        :bits => "1fffffff",   # 4 leading zeroes
        :nonce => 0,
      },
      :parent => %{
        :version => 1,
        :previous_block => "0000000000000000000000000000000000000000000000000000000000000001",
        :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
        :timestamp => 1231006505,
        :bits => "1fffffff",   # 4 leading zeroes
        :nonce => 0,
      },
      :hash => nil,
      :txn => nil,
      :coinbase_txn => nil
    }
    
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
    IO.puts "Mining Genesis Block..."
    :timer.sleep(1000)
    
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
      Peer.create_txn(user1, {wallet_add_user2, 34})
      :timer.sleep(200)
    end)

    :timer.sleep(1000)
    state = Peer.get_state(miner_pid)
    check_length = 4
    assert length(state[:blockchain]) == check_length
  end
end
