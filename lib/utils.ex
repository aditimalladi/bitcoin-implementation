defmodule Utils do

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

end