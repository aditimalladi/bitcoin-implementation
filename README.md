# Bitcoin Implementation
This project explores the implementation of the bitcoin protocol.

Bitcoin uses peer-to-peer technology to operate with no central authority or banks; managing transactions and the issuing of bitcoins is carried out collectively by the network. Bitcoin is open-source; its design is public, nobody owns or controls Bitcoin and everyone can take part. Through many of its unique properties, Bitcoin allows exciting uses that could not be covered by any previous payment system.

## What is implemented
In the current project the following components are working:

* **Difficulty** - 
Difficulty is a measure of how difficult it is to find a hash below a given target.
The Bitcoin network has a global block difficulty. Valid blocks must have a hash below this target. Mining pools also have a pool-specific share difficulty setting a lower limit for shares.

In the current project we have set the difficulty sufficiently low to be able to accomodate very fast computation. The target value is a 4 byte integer as defined below in an encoded format(as done in the bitcoin protocol)
```
 difficulty = "1fffffff"
```

* **Coinbase Transactions** -
Transactions that are executed on networks such as Bitcoin are batched together to form a block. These blocks are then included on the blockchain to form an immutable and tamper-resistant record of all transactions that are made on the network. Each block added to the blockchain must include one or more transactions, and the first transaction required in that block is called the coinbase transaction, which is also known as the generation transaction.
Coinbase transactions are always constructed by a miner and will contain a reward for efforts expended during the proof of work mining process.

In our implementation the miner adds a coinbase transaction just before mining the said block. This enables the miner to recieve the "reward coins".

* **Hash Calculation** - 
All the hash calculation's internal byte order is in the Little Endian Format
The hashing of the block header is done in the same manner as the Bitcoin Protocol, which is as follows: 
  1. All the integers are encoded to 4 byte values
  2. All the Hashes are 32 byte values in Little Endian Order
  3. Combine the various components to form a message. This includes: version, previous block's hash, merkle root of the current block, timestamp, difficulty and nonce (in this particular order).
  4. The message is then decoded back to binary
  5. The binary message is then double hashed using the SHA-256 algorithm
  6. The resulting hash is encoded to hex and the endian-ness is reversed back(to Big Endian).


* **Mining** - 
Bitcoin Mining is a peer-to-peer computer process used to secure and verify bitcoin transactions—payments from one user to another on a decentralized network. Mining involves adding bitcoin transaction data to Bitcoin's global public ledger of past transactions. Each group of transactions is called a block. Blocks are secured by Bitcoin miners and build on top of each other forming a chain. This ledger of past transactions is called the blockchain. The blockchain serves to confirm transactions to the rest of the network as having taken place. Bitcoin nodes use the blockchain to distinguish legitimate Bitcoin transactions from attempts to re-spend coins that have already been spent elsewhere.

**Mining Procedure in current project** - 
The miner continously polls the transaction pool. Once the miner picks up a transaction, it creates a new block, add a new coinbase tranaction and mine the new block.
Before proceeding to mine the new picked up transaction the miner **verifies the transaction** to ensure that the user sending the money has the minimum required resources. 
Once this new block is mined it is then broadcasted to the entire peer network. 
Each Peer who receives the broadcast message, verifies the block and **only then** adds it to it's own copy of the blockchan, dropping those blocks for which the verification fails.

**OVERALL PROCEDURE:**
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
```

* One Miner is initialsed, who can check and mine any pending transactions

* The Miner then mines the first block/ genesis block. This is then added to the blockchain and broadcasted to any other Peers present in the network.

* Each Peer now can start transacting.
First to generate intial coins each Peer needs to mine empty blocks to collect the mining reward. 
This is a way expend Compute Resources and mine coins. 

* Now a randomly selected Peer, sends a random amount to one of it's peer. This would constitute creating a new transaction and therefore a new block on the blockchain.

## IMPLEMENTED STRUCTURES

### BLOCK STRUCTURE

********************************************
*                                          *
*                 HEADER                   *
*                                          *   
********************************************
*                                          *
*               BLOCK HASH                 *
*                                          *
********************************************
*                                          *
*               TRANSACTION                *
*                                          *
********************************************
*                                          *
*          COINBASE TRANSACTION            *
*                                          *
********************************************

### BLOCK HEADER STRUCTURE

********************************************
*                                          *
*                 VERSION                  *
*                                          *   
********************************************
*                                          *
*           PREVIOUS BLOCK HASH            *
*                                          *
********************************************
*                                          *
*         MERKLE ROOT OF THE BLOCK         *
*                                          *
********************************************
*                                          *
*                 TIMESTAMP                *
*                                          *
********************************************
*                                          *
*                DIFFICULTY                *
*                                          *
********************************************
*                                          *
*                  NONCE                   *
*                                          *
********************************************

### TRANSACTION STRUCTURE

********************************************
*                                          *
*            FROM WALLET ADDRESS           *
*                                          *   
********************************************
*                                          *
*             TO WALLET ADDRESS            *
*                                          *
********************************************
*                                          *
*                 TIMESTAMP                *
*                                          *
********************************************
*                                          *
*                  AMOUNT                  *
*                                          *
********************************************
*                                          *
*                 SIGNATURE                *
*                                          *
********************************************
*                                          *
*               COINBASE FLAG              *
*                                          *
********************************************


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
   98.44%  | Peer
   93.20%  | Utils
   **95.43%**| **Total**
