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

      # generate a new block
      new_block = Utils.generate_block(tx, prev_block)
      # remove the timestamp from the block as that will be real time and can change.
      header = new_block[:header]
      header = Map.delete(header, :timestamp)
      new_block = Map.replace(new_block, :header, header)

      check_block = %{
        coinbase_txn: nil,
        hash: nil,
        header: %{
          bits: "1effffff",
          merkle_root: "a2cc2cf99ad4011fbf8e5082b353a24009f5b6bf2cca8674d29fb04044ae87ac",
          nonce: 0,
          previous_block: nil,
          # timestamp: 1543100352,
          version: 1
        },
        parent: %{
          bits: "1effffff",
          merkle_root: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
          nonce: 0,
          previous_block: "0000000000000000000000000000000000000000000000000000000000000000",
          timestamp: 1_231_006_505,
          version: 1
        },
        txn: %{
          amt: 10,
          coinbase_flag: true,
          from: "",
          signature:
            "304402202454d10ff0df17b87eb85dfebbdcbf22bd1edd8a9b55a8eefa386f91e0cd0a2f0220319d7a6c7e1a3b907b6c771cbaabb5585141c67e9944d37da333b16ef49c0bbf",
          timestamp: 1_543_095_711,
          to: "a891e1b6146459314868bc44810bbb02e9ab12c5"
        }
      }

      assert new_block == check_block
    end
  end

  describe "Txn Block Hash" do
    test "Checking for the signature" do
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

      new_hash = Utils.hash_block_data(tx)

      check_hash =
        <<162, 204, 44, 249, 154, 212, 1, 31, 191, 142, 80, 130, 179, 83, 162, 64, 9, 245, 182,
          191, 44, 202, 134, 116, 210, 159, 176, 64, 68, 174, 135, 172>>

      assert check_hash == new_hash
    end
  end

  # TODO: Test for mining a block - genesis
  # 000027147f8b9646b441afcdfcadc1e69174f54f7615c178152614c58ef36465 (Check this output)
end
