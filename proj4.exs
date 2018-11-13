[numUsers, numTxn] = System.argv

{numUsers, _} = Integer.parse(numUsers)
{numTxnn, _} = Integer.parse(numTxn)

#create Genesis block
genesis_block = %{
  :header => %{
    :version => 1,
    :previous_block => "0000000000000000000000000000000000000000000000000000000000000000",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => "1effffff",
    :nonce => 0,
  }
}

mined_block_header = Utils.mine_block(genesis_block[:header])
IO.inspect Utils.get_block_hash(mined_block_header)





