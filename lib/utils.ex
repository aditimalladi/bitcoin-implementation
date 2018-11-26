defmodule Utils do
  import Binary

  # takes a hex-string and reverses it's endianness
  def reverse_endian(hex_string) do
    if(hex_string == nil)do
      IO.inspect hex_string
      IO.puts "WHAT THE SHIT"
    end
    {:ok, binary_string} = hex_string |> Base.decode16(case: :lower)

    binary_string
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
    |> Base.encode16(case: :lower)
  end

  # takes an integer, zero pads to 32 bits, reverse endianness and converts to hex
  def encode_integer(n) do
    # IO.puts "Encode Integer"
    # IO.inspect n
    <<n::signed-little-integer-size(32)>> |> Base.encode16(case: :lower)
  end

  # TODO: check for errors
  # calculates the block hash
  def get_block_header_hash(block_header) do
    # IO.puts "In get_block _header_hash"
    # IO.inspect block_header
    # IO.inspect block_header[:version]
    version = encode_integer(1)
    # IO.puts "In #1"
    # IO.inspect block_header[:version]

    # IO.inspect block_header[:previous_block]
    previous_block = reverse_endian(block_header[:previous_block])
    merkle_root = reverse_endian(block_header[:merkle_root])
    timestamp = encode_integer(block_header[:timestamp])
    # IO.puts "In #2"
    # IO.inspect block_header[:timestamp]
    # bits is the difficulty
    bits = reverse_endian(block_header[:bits])
    nonce = encode_integer(block_header[:nonce])
    # IO.puts "In #3"
    # IO.inspect block_header[:nonce]
    # data to be hashed to get the current block hash
    message = version <> previous_block <> merkle_root <> timestamp <> bits <> nonce
    # covert the data into binary format
    {:ok, binary_string} = Base.decode16(message, case: :lower)
    # double SHA 
    first_pass = :crypto.hash(:sha256, binary_string)
    second_pass = :crypto.hash(:sha256, first_pass)
    # covert back to hex and reverse the endian-ness
    second_pass |> Base.encode16(case: :lower) |> reverse_endian
  end

  # recursive function to check mine the block
  def mine_block(block_header, p \\ false) do
    if p do
      IO.puts "Mining!"
      IO.inspect block_header
    end
    block_hash = get_block_header_hash(block_header)

    if check_target(block_hash, block_header[:bits]) do
      block_header
    else
      block_header = Map.replace(block_header, :nonce, block_header[:nonce] + 1)
      mine_block(block_header)
    end
  end

  # checks if the calculated hash to see if a block is confirmed
  def check_target(hash, target) do
    target_value = target_to_value(target)
    {hash_value, _} = Integer.parse(hash, 16)

    if hash_value < target_value do
      true
    else
      false
    end
  end

  # expanding target to a 32 byte integer
  def target_to_value(target) do
    {target, _} = Integer.parse(target, 16)
    {<<num>>, digits} = target |> Binary.from_integer() |> split_at(1)

    digits
    |> trim_trailing
    |> pad_trailing(num)
    |> to_integer
  end

  # generates a new txn
  # also posts the new txn into the pending pool
  def generate_tx(data) do
    {from, to, amount, private_key} = data

    tx = %{
      # empty string if no from address
      :from => from,
      :to => to,
      :timestamp => :os.system_time(:seconds),
      :amt => amount,
      :signature => nil,
      # default is set to false, set to true when there is no :from address 
      :coinbase_flag => if(from == "", do: true, else: false)
    }

    tx = Map.replace(tx, :signature, sign(tx, private_key))
    tx
  end

  # function to generate a block from each txn
  # each block contains ONE txn
  def generate_block(txn, prev_block, coinbase_txn) do
    # IO.inspect prev_block[:hash]
    # prev_block[:hash]
    block = %{
      :header => %{
        :version => 1,
        :previous_block => prev_block[:hash],
        :merkle_root => hash_block_data(txn, coinbase_txn) |> Base.encode16(case: :lower),
        :timestamp => :os.system_time(:seconds),
        # 4 leading zeroes
        :bits => "1fffffff",
        :nonce => 0
      },
      :parent => prev_block[:header],
      :hash => nil,
      :txn => txn,
      :coinbase_txn => coinbase_txn
    }
    # IO.inspect block
    block
  end

  # send the entire the tx block
  def sign(tx_block, private_key) do
    msg = hash_txn_data(tx_block)
    signature =
      :crypto.sign(:ecdsa, :sha256, msg, [private_key, :secp256k1]) |> Base.encode16(case: :lower)

    signature
  end

  # verifying the digital sign

  # TODO: Account for the case when from is = "" 
  # cause ets lookup will not work
  def verify_sign(tx_block) do
    msg = hash_txn_data(tx_block)
      # tx_block[:from] <>
      #   tx_block[:to] <>
      #   Integer.to_string(tx_block[:amt]) <> Integer.to_string(tx_block[:timestamp])

    # msg = :crypto.hash(:sha256, msg)
    {:ok, signature} = tx_block[:signature] |> Base.decode16(case: :lower)
    [{_, map}] = :ets.lookup(:data, tx_block[:from])
    public_key = map[:public_key]
    :crypto.verify(:ecdsa, :sha256, msg, signature, [public_key, :secp256k1])
  end

  # dynamically calculate the current money from the blockchain
  def calc_money(blockchain, address) do
    current_money =
      Enum.map(blockchain, fn block ->
        cond do
          block[:txn][:from] == address ->
            -block[:txn][:amt]

          block[:txn][:to] == address ->
            block[:txn][:amt]

          true ->
            0
        end
      end)

    Enum.sum(current_money)
  end

  # verifying the block before picking up txn
  # in the current implementation Rewards txns are signed by the miner posting the reward/ collecting reward
  def verify_txn(tx_block, blockchain) do
    if(tx_block[:coinbase_flag]) do
      verify_sign(tx_block)
    else
      from_address = tx_block[:from]
      [{_, map}] = :ets.lookup(:data, from_address)
      pid = map[:pid]
      # state = Peer.get_state(pid)
      # blockchain = state[:blockchain]
      money_available = calc_money(blockchain, from_address)
      tx_block[:amt] >= money_available && verify_sign(tx_block)
  end
end

  # verify's the block
  def verify_block(block, blockchain) do
    tx_block = block[:txn]
    # calculate and check block data hash
    if(tx_block == nil)do
      msg = Utils.hash_txn_data(block[:coinbase_txn]) |> Base.encode16(case: :lower)
      block_header = block[:header]
      check_block_data_hash = block_header[:merkle_root] == msg
      # now to check previous block data hash
      prev_block = List.last(blockchain)
      recalculated_prev_hash = get_block_header_hash(prev_block[:header])
      check_prev_hash = recalculated_prev_hash == block_header[:previous_block]
      # now verify the txn in the block
      # now verify the current block's hash
      block_header_hash = get_block_header_hash(block_header)
      check_block_header_hash = block_header_hash == block[:hash]
      # IO.puts "Printing all the boolean values"
      # IO.inspect check_block_data_hash
      # IO.inspect check_prev_hash
      # IO.inspect check_block_header_hash
      check_block_data_hash && check_prev_hash && check_block_header_hash
    else
      msg = hash_block_data(tx_block, block[:coinbase_txn]) |> Base.encode16(case: :lower)
      block_header = block[:header]
      check_block_data_hash = block_header[:merkle_root] == msg
      # now to check previous block data hash
      prev_block = List.last(blockchain)
      recalculated_prev_hash = get_block_header_hash(prev_block[:header])
      check_prev_hash = recalculated_prev_hash == block_header[:previous_block]
      # now verify the txn in the block
      check_txn = verify_txn(tx_block, blockchain)
      # now verify the current block's hash
      block_header_hash = get_block_header_hash(block_header)
      check_block_header_hash = block_header_hash == block[:hash]
      check_block_data_hash && check_prev_hash && check_txn && check_block_header_hash
    end
  end

  def hash_txn_data(tx_block) do
    msg =
      tx_block[:from] <>
        tx_block[:to] <>
        Integer.to_string(tx_block[:amt]) <> Integer.to_string(tx_block[:timestamp])
    
   :crypto.hash(:sha256, msg)
  end

  # function to hash block data (calc merkle root)
  def hash_block_data(tx_block, coinbase_txn) do
    if (tx_block == nil) do
      hash_txn_data(coinbase_txn)
    else
      # IO.puts "Inside the hash_blcok_data"
      # IO.inspect tx_block
      msg1 =
      tx_block[:from] <>
        tx_block[:to] <>
        Integer.to_string(tx_block[:amt]) <> Integer.to_string(tx_block[:timestamp])
      msg1= :crypto.hash(:sha256, msg1) |> Base.encode16(case: :lower)
      msg2 = 
        coinbase_txn[:from] <>
          coinbase_txn[:to] <>
          Integer.to_string(coinbase_txn[:amt]) <> Integer.to_string(coinbase_txn[:timestamp])
      msg2 = :crypto.hash(:sha256, msg2) |> Base.encode16(case: :lower)
      #calc and return merkle root
      :crypto.hash(:sha256, msg1<>msg2)
    end
  end

  # FORMAT - {walletaddress - {publicKey, pid}}
  def broadcast(block)do
    IO.puts "Broadcast"
    [{_, pids}] = :ets.lookup(:data, :pids)
    # IO.puts "Keys"
    # IO.inspect pids
    Enum.each(pids, fn pid ->
      IO.puts "Broadcast Repeated"
      # {wallet_address, %{:pid => pid, :public_key => public_key}} = :ets.lookup(:data, key)
      if(!(pid == self())) do
        Peer.add_block(pid, block)
      end
    end)
  end

  def broadcast_genesis(block)do
    IO.puts "Broadcast - Genesis"
    [{_, pids}] = :ets.lookup(:data, :pids)
    # IO.puts "Keys"
    # IO.inspect pids
    Enum.each(pids, fn pid ->
      IO.puts "Broadcast Genesis Repeated"
      # {wallet_address, %{:pid => pid, :public_key => public_key}} = :ets.lookup(:data, key)
      if(!(pid == self())) do
        Peer.add_genesis_block(pid, block)
      end
    end)
  end





  def key_stream(table_name) do
    Stream.resource(
      fn -> :ets.first(table_name) end,
      fn :"$end_of_table" -> {:halt, nil}
         previous_key -> {[previous_key], :ets.next(table_name, previous_key)} end,
      fn _ -> :ok end)
  end

end
