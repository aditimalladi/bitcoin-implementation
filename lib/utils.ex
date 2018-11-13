defmodule Utils do

  import Binary

  # takes a hex-string and reverses it's endianness
  def reverse_endian(hex_string) do
    {:ok, binary_string} = Base.decode16(hex_string, case: :lower) 
    binary_string |>:binary.bin_to_list 
    |> Enum.reverse 
    |> :binary.list_to_bin 
    |> Base.encode16(case: :lower)
  end

  # takes an integer, zero pads to 32 bits, reverse endianness and converts to hex
  def encode_integer(n) do
    <<n::signed-little-integer-size(32)>> |> Base.encode16(case: :lower)
  end

  # calculates the block hash
  def get_block_hash(block_header) do
    version = encode_integer(block_header[:version])
    previous_block = reverse_endian(block_header[:previous_block])
    merkle_root = reverse_endian(block_header[:merkle_root])
    timestamp = encode_integer(block_header[:timestamp])
    bits = reverse_endian(block_header[:bits])
    nonce = encode_integer(block_header[:nonce])

    message = version <> previous_block <> merkle_root <> timestamp <> bits <> nonce

    {:ok, binary_string} = Base.decode16(message, case: :lower)
    first_pass = :crypto.hash(:sha256, binary_string)
    second_pass = :crypto.hash(:sha256, first_pass)

    second_pass |> Base.encode16(case: :lower) |> reverse_endian
  end

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

  def target_to_value(target) do
    {target, _} = Integer.parse(target, 16)
    {<<num>>, digits} = target |> Binary.from_integer |> split_at(1)
    digits
    |> trim_trailing
    |> pad_trailing(num)
    |> to_integer
  end

end