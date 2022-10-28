# Exorde Protocol Documentation!

**Protocol Interactions & Rules**.


# Network information

In order to connect, the available network configuration is available here:
https://github.com/MathiasExorde/TestnetProtocol-staging/blob/main/NetworkConfig.txt

The main information to connect and start reading/writing to the Exorde blockchain are:

 - RPC Endpoint: "https://mainnet.skalenodes.com/v1/light-vast-diphda",
 -  Chain ID: "2139927552"
- The blockExplorer can be found here: "https://light-vast-diphda.explorer.mainnet.skalenodes.com/",

Once connected to the right network, it is time to connect to the core protocol endpoints.

## Core protocol endpoints

Exorde Protocol is composed of several layers, from core to external service:

- **Core Endpoints**: **DAO Avatar, Main Controller, Permission Registry, Exorde Token**. These should not change, once deployed, these contracts & adresses stay forever.
- **Base Systems**: **StakingManager, RewardsManager, ConfigRegistry, Parameters, AddressManager, MasterWalletScheme**. These contract handle the Staking, Rewards, Master/Main Mapping, Global configuration & System Parameters, they are controlled by the Core contract & the governance, and can be updated over time.
- **Data-specific Systems**: **DataSpotting, DataCompliance, DataIndexing & DataArchiving**. These compose the data pipeline that is handling the stream of data blocks produced by Exorde Spotters. They work with the Base Systems to rewards Reputation & Tokens, they read their own parameters from the Parameters contract, etc.

The latest contract endpoints can be found usually here: https://github.com/MathiasExorde/TestnetProtocol-staging/blob/main/ContractsAddresses.txt
Later, only the Core Endpoints need to be trusted, as the other systems are appointed (& permissioned) by the Exorde governance. 

## ABIs

In order to interact (read or write to) the contracts composing the protocol, you will need to interface via their respectives ABIs. These can be found here: https://github.com/MathiasExorde/TestnetProtocol-staging/tree/main/ABIs.
ABIs are jsons and for example, DataSpotting ABI itself can be found at https://github.com/MathiasExorde/TestnetProtocol-staging/blob/main/ABIs/DataSpotting.sol/DataSpotting.json in the sub item "abi" of this larger json file.

**The Protocol is a set of contracts with a set of precise functions (endpoints)**. To read/write a given protocol function (simple getters or state-modifying functions), you need to interface to the contract hosting this precise function, with its ABI.
Examples:

To read the given Reputation balance of an address: On the Reputation contract, using the function *BalanceOf(address)*.
To read the Available Stake of an address: On the StakingManager, using the function *AvailableStakedAmountOf(address)*.

## Reading User General State 

For a given worker wallet address, we can read its "state":

 - REP: *BalanceOf(address)* on Reputation contract EXDT Available
 - Rewards: *RewardsBalanceOf(..)* on the RewardsManager contract
 - Stakes: *balances(..), AvailableStakedAmountOf(..), AllocatedStakedAmountOf(..)* on StakingManager
 - Current Main Address: *FetchHighestMaster(..)*
 - Current Master (if set): *getMaster(..)*

User stakes are composed of 3 balances (readable with the balances() call):
- **Free Balance**: when user deposit tokens to the StakingManager, the end up here. All tokens in the balance can be withdrawn at will.
- **Staked Balance**: this balance is staked and can be allocated to Systems during participation (and released later depending on the processes)
- **Allocated Balance**: this balance is what is currently locked. This will change soon to show which systems are allocating what, and allow the StakingManager administrator to release these balances if needed (Change of Systems, updates, etc).

## Reading Global General State

Total Reputation, Rewards, Stake are easily readable. (...)

## Export a file

You can export the current file by clicking **Export to disk** in the menu. You can choose to export the file as plain Markdown, as HTML using a Handlebars template or as a PDF.

## Main WorkSystem

A user can do two things on DataSpotting (the main WorkSystem now):
 -  Spot Data
 -  Participate in the Validation 
 
Spotting Data (the input of the system) is as follows:
**SpotData(string[] memory file_hashs, string[] calldata URL_domains, uint256 item_count_, string memory extra_)**
-- file_hashs is a list of hashes, but can be a list of 1 file (currently that is what is done, spotting N files is not necessary at once)
-- URL_domains is a list of the main domain being spotted in the respective file, file_hashs and URL_domains must have same length
-- item_count_ is the number of item in the file (will be a list later)

Participating in the Validation is done with a commit-reveal scheme.
 - **commitSpotCheck(uint256  _DataBatchId, bytes32  _encryptedHash, bytes32  _encryptedVote, uint256  _BatchCount, string  memory  _From)**
- **revealSpotCheck(uint256  _DataBatchId, string  memory  _clearIPFSHash, uint256  _clearVote, uint256  _salt)**

**Participating has requirements.**

 The sender must have either:
1.  **Already enough Stake allocated** in this specific WorkSystem ( *SystemStakedTokenBalance(address)* )
2.  **Enough AvailableStake on StakingManager**, or have a Master/Main who has enough AvailableStake, in order for the WorkSystem to automatically ask the StakingManager for some Stake to get allocated.

If not enough AvailableStake (and nothing staked in the WorkSystem already), an address must do the following:

 1. Get enough tokens (25 is currently what is needed to participate) - not a problem on the Testnet
 2. Approve(num_tokens) on the EXDT Token Contract, to allow a transfer
 3. Deposit(num_tokens) on the StakingManager contract: will transfer the tokens & credit your free_balance.
 4. Stake(num_tokens) on the StakingManager contract, will move tokens from the free_balance to the staked_balanc


*All numbers must be divided by 10^18 to be displayed. 100000000000000000000 = 100 EXDT (or 100 REP).*
