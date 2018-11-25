# BitcoinImplementation

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bitcoin_implementation` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bitcoin_implementation, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bitcoin_implementation](https://hexdocs.pm/bitcoin_implementation).




Block Structure:
```
genesis_block = %{
  :header => %{
    :version => 1,
    :previous_block => "0000000000000000000000000000000000000000000000000000000000000000",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => "1effffff",   # 4 leading zeroes
    :nonce => 0,
  },
  :parent => nil,
  :hash => nil,
  :txn => nil
}

```

Had to do this : 
```
$mix deps.get
```