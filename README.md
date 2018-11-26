# Bitcoin Implementation
This project explores the implementation of the bitcoin protocol.

Bitcoin uses peer-to-peer technology to operate with no central authority or banks; managing transactions and the issuing of bitcoins is carried out collectively by the network. Bitcoin is open-source; its design is public, nobody owns or controls Bitcoin and everyone can take part. Through many of its unique properties, Bitcoin allows exciting uses that could not be covered by any previous payment system.

## What is implemented
In the current project the following components are working:

* We have an inital Genesis Block.
  A genesis block is the first block of a block chain. We have defined the first genesis block with the traditional format used in the bitcoin
  ```
  genesis_block = %{
  :header => %{
    :version => 1,
    :previous_block => "0000000000000000000000000000000000000000000000000000000000000000",
    :merkle_root => "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
    :timestamp => 1231006505,
    :bits => "1effffff",
    :nonce => 0,
  },
  :parent => nil,
  :hash => nil,
  :txn => nil
}

* One Miner is initialsed, who can check and mine any pending transactions

* The Miner then mines the first block/ genesis block. This is then added to the blockchain and broadcasted to any other Peers present in the network.

* Each Peer now can start transacting.
First to generate intial coins each Peer needs to mine empty blocks to collect the mining reward. 
This is a way expend Compute Resources and mine coins. 

* Now a randomly selected Peer, sends a random amount to one of it's peer. This would constitute creating a new transaction and therefore a new block on the blockchain.


## Getting Started with the Project ...

**Input** 
It takes in 2 commandline integers
```numUsers``` -  The total number of Peers participating in the network
```numTxn```   -  The total number of transactions executed in the blockchain

### Fetch dependencies:  
```
$ mix deps.get
```

### Running the program:
```
$ mix run proj4.exs 2 2
```

### Run tests: 
```
$ mix test
```

**Test Coverage Achieved**

Percentage | Module
-----------|-----------------------
   100.00% | Pool
   100.00% | BitcoinImplementation
    98.44% | Peer
    93.20% | Utils
-----------|-----------------------
    95.43% | Total
