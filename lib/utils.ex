defmodule Utils do
  import Binary

  # takes a hex-string and reverses it's endianness
  def reverse_endian(hex_string) do
    {:ok, binary_string} = Base.decode16(hex_string, case: :lower)

    binary_string
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
    |> Base.encode16(case: :lower)
  end

  # takes an integer, zero pads to 32 bits, reverse endianness and converts to hex
  def encode_integer(n) do
    <<n::signed-little-integer-size(32)>> |> Base.encode16(case: :lower)
  end

  # calculates the block hash
  def get_block_header_hash(block_header) do
    version = encode_integer(block_header[:version])
    previous_block = reverse_endian(block_header[:previous_block])
    merkle_root = reverse_endian(block_header[:merkle_root])
    timestamp = encode_integer(block_header[:timestamp])
    # bits is the difficulty
    bits = reverse_endian(block_header[:bits])
    nonce = encode_integer(block_header[:nonce])
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
  def mine_block(block_header) do
    block_hash = get_block_hash(block_header)
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
      :coinbase_flag => false
    }
    tx = Map.replace(tx, :signature, sign(tx, private_key))
    Pool.put_txn(MyPool, tx)
    tx
  end

  # send the entire the tx block
  def sign(tx_block, private_key) do
    msg = hash_block_data(tx_block)
    signature =
      :crypto.sign(:ecdsa, :sha256, msg, [private_key, :secp256k1]) |> Base.encode16(case: :lower)
    signature
  end

  # verifying the digital sign
  def verify_sign(tx_block) do
    msg =
      tx_block[:from] <>
        tx_block[:to] <>
        Integer.to_string(tx_block[:amt]) <> Integer.to_string(tx_block[:timestamp])
    msg = :crypto.hash(:sha256, msg)
    {:ok, signature} = tx_block[:signature] |> Base.decode16(case: :lower)
    {_, public_key} = :ets.lookup(:data, tx_block[:from])
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
  def verify_txn(tx_block) do
    if(tx_block[:coinbase_flag]) do
      verify_sign(tx_block)
    else
      from_address = tx_block[:from]
      {_, map} = :ets.lookup(:data, from_address)
      pid = map[:pid]
      state = Peer.get_state(pid)
      blockchain = state[:blockchain]
      money_available = calc_money(blockchain, from_address)
      tx_block[:amt] >= money_available && verify_sign(tx_block)
    end
  end

  # verify's the block
  def verify_block(block) do
    tx_block = block[:txn]
    # calculate and check block data hash
    msg = hash_block_data(tx_block) |> Base.encode16(case: :lower)
    block_header = block[:header]
    check_block_data_hash = (block_header[:merkle_root] == msg)
    # now to check previous block data hash
    recalculated_prev_hash = get_block_header_hash(block[:parent])
    check_prev_hash = (recalculated_prev_hash == block_header[:previous_block])
    # now verify the txn in the block
    check_txn = verify_txn(tx_block)
    # now verify the current block's hash
    block_header_hash = get_block_header_hash(block_header)
    check_block_header_hash = (block_header_hash == block[:hash])
    check_block_data_hash && check_prev_hash && check_txn && check_block_header_hash
  end

  # function to hash block data (calc merkle root)
  def hash_block_data(tx_block) do
    msg =
    tx_block[:from] <>
      tx_block[:to] <>
      Integer.to_string(tx_block[:amt]) <> Integer.to_string(tx_block[:timestamp])
    msg = :crypto.hash(:sha256, msg)
    msg
  end
end
