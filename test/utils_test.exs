defmodule WorkerTest do
  use ExUnit.Case, async: True

  describe "takes an integer, zero pads to 32 bits, reverse endianness and converts to hex" do
    test "checks the output for a given integer" do
      assert Utils.encode_integer(10) == "0a000000"
    end
  end

  describe "Reverse Endian" do
    test "Checking reverse Endian" do
      assert Utils.reverse_endian("00001234") == "34120000"
    end
  end

  # TODO: Route back to this
  describe "Check by sending to a randomly generated address" do
    test "Generate Txn" do
      from = ""
      to = "a891e1b6146459314868bc44810bbb02e9ab12c5"
      amount = 10

      private_key =
        <<147, 216, 167, 38, 5, 130, 27, 228, 145, 57, 86, 67, 204, 171, 196, 158, 148, 140, 222,
          173, 53, 236, 113, 8, 247, 47, 54, 238, 104, 254, 110, 77>>

      # data = {from, to, amount, private_key}
      new_tx = Utils.generate_tx({from, to, amount, private_key})

      check_tx = %{
        amt: 10,
        coinbase_flag: true,
        from: "",
        signature:
          "304402202454d10ff0df17b87eb85dfebbdcbf22bd1edd8a9b55a8eefa386f91e0cd0a2f0220319d7a6c7e1a3b907b6c771cbaabb5585141c67e9944d37da333b16ef49c0bbf",
        timestamp: 1_543_095_711,
        to: "a891e1b6146459314868bc44810bbb02e9ab12c5"
      }

      assert new_tx = check_tx
    end
  end

  describe "Generate Block" do
    test "Generate Block" do
      # new_block = Utils.generate_block(txn, block)
      tx = %{
        amt: 10,
        coinbase_flag: true,
        from: "",
        signature:
          "304402202454d10ff0df17b87eb85dfebbdcbf22bd1edd8a9b55a8eefa386f91e0cd0a2f0220319d7a6c7e1a3b907b6c771cbaabb5585141c67e9944d37da333b16ef49c0bbf",
        timestamp: 1_543_095_711,
        to: "a891e1b6146459314868bc44810bbb02e9ab12c5"
      }

      prev_block = %{
        :header => %{
          :version => 1,
          :previous_block => "0000000000000000000000000000000000000000000000000000000000000000",
          :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
          :timestamp => 1_231_006_505,
          # 4 leading zeroes
          :bits => "1effffff",
          :nonce => 0
        },
        :parent => nil,
        :hash => nil,
        :txn => nil
      }

      coinbase_txn = %{
        amt: 100,
        coinbase_flag: true,
        from: "",
        signature: "3045022100c79ee81acb97d3388ce3a127747aaa38c4d4ab0243403ae1de6653ff50a841da022025d6eb0b0dd3ecbd945bc1b6d97ae2a30cbc20bed4582c4a7cf5de65691c9f93",
        timestamp: 1543255666,
        to: "34026f1b0062c4fca1721454458d155f43973802"
      }

      # generate a new block
      new_block = Utils.generate_block(tx, prev_block, coinbase_txn)
      # IO.inspect new_block
      # remove the timestamp from the block as that will be real time and can change.
      header = new_block[:header]
      header = Map.delete(header, :timestamp)
      new_block = Map.replace(new_block, :header, header)

      check_block = %{
        coinbase_txn: %{
          amt: 100,
          coinbase_flag: true,
          from: "",
          signature: "3045022100c79ee81acb97d3388ce3a127747aaa38c4d4ab0243403ae1de6653ff50a841da022025d6eb0b0dd3ecbd945bc1b6d97ae2a30cbc20bed4582c4a7cf5de65691c9f93",
          timestamp: 1543255666,
          to: "34026f1b0062c4fca1721454458d155f43973802"
        },
        hash: nil,
        header: %{
          bits: "1fffffff",
          merkle_root: "13ddcccdfe3529825ca85c176d74b11bd86f82a46733278ac6599ef2c374f260",
          nonce: 0,
          previous_block: nil,
          version: 1
        },
        parent: %{
          bits: "1effffff",
          merkle_root: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
          nonce: 0,
          previous_block: "0000000000000000000000000000000000000000000000000000000000000000",
          timestamp: 1231006505,
          version: 1
        },
        txn: %{
          amt: 10,
          coinbase_flag: true,
          from: "",
          signature: "304402202454d10ff0df17b87eb85dfebbdcbf22bd1edd8a9b55a8eefa386f91e0cd0a2f0220319d7a6c7e1a3b907b6c771cbaabb5585141c67e9944d37da333b16ef49c0bbf",
          timestamp: 1543095711,
          to: "a891e1b6146459314868bc44810bbb02e9ab12c5"
        }
      }

      assert new_block == check_block
    end
  end

  describe "Txn Block Hash" do
    test "Hash Block Data" do
      # taking an arbitary private key for testing only
      private_key =
        <<147, 216, 167, 38, 5, 130, 27, 228, 145, 57, 86, 67, 204, 171, 196, 158, 148, 140, 222,
          173, 53, 236, 113, 8, 247, 47, 54, 238, 104, 254, 110, 77>>

      tx = %{
        amt: 10,
        coinbase_flag: true,
        from: "",
        signature:
          "304402202454d10ff0df17b87eb85dfebbdcbf22bd1edd8a9b55a8eefa386f91e0cd0a2f0220319d7a6c7e1a3b907b6c771cbaabb5585141c67e9944d37da333b16ef49c0bbf",
        timestamp: 1_543_095_711,
        to: "a891e1b6146459314868bc44810bbb02e9ab12c5"
      }

      coinbase_txn = %{
        amt: 100,
        coinbase_flag: true,
        from: "",
        signature: "3045022100c79ee81acb97d3388ce3a127747aaa38c4d4ab0243403ae1de6653ff50a841da022025d6eb0b0dd3ecbd945bc1b6d97ae2a30cbc20bed4582c4a7cf5de65691c9f93",
        timestamp: 1543255666,
        to: "34026f1b0062c4fca1721454458d155f43973802"
      }

      new_hash = Utils.hash_block_data(tx, coinbase_txn)

      check_hash = <<19, 221, 204, 205, 254, 53, 41, 130, 92, 168, 92, 23, 109, 116, 177, 27, 216,
                    111, 130, 164, 103, 51, 39, 138, 198, 89, 158, 242, 195, 116, 242, 96>>

      assert new_hash == check_hash
    end
  end

  describe "Block Header Hash" do
    test "Block Header Hash" do
      genesis_header = %{
        :version => 1,
        :previous_block => "6a275a8bd87fbdf78d4a7ecf9f65d8d21ba7b34f327a1594553a449ff0403627",
        :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
        :timestamp => 1231006505,
        :bits => "1fffffff",   # 4 leading zeroes
        :nonce => 0,
      }
      check_hash = "87e6af7e87f5bf596386c7367a03ca6152950b71ad0ab85493920d368db03583"
      assert Utils.get_block_header_hash(genesis_header) == check_hash
    end
  end
end
