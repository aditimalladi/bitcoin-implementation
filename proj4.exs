[numUsers, numTxn] = System.argv

{numUsers, _} = Integer.parse(numUsers)
{numTxnn, _} = Integer.parse(numTxn)

#create Genesis block
block = %{:header => 
  %{:prev_hash = "0", :nonce => nil, :hash => :crypto.hash(:sha256, "suckers") |> Base.encode16}
, :data => "suckers"}


