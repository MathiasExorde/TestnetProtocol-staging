// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
* @title WorkSystem Spot v1.3.4a
* @author Mathias Dail - CTO @ Exorde Labs 2022
*/

// File: dll/DLL.sol

library DLL {
    uint256 constant NULL_NODE_ID = 0;

    struct Node {
        uint256 next;
        uint256 prev;
    }

    struct SpottedData {
        mapping(uint256 => Node) dll;
    }

    function isEmpty(SpottedData storage self) public view returns (bool) {
        return getStart(self) == NULL_NODE_ID;
    }

    function contains(SpottedData storage self, uint256 _curr) public view returns (bool) {
        if (isEmpty(self) || _curr == NULL_NODE_ID) {
            return false;
        }

        bool isSingleNode = (getStart(self) == _curr) && (getEnd(self) == _curr);
        bool isNullNode = (getNext(self, _curr) == NULL_NODE_ID) && (getPrev(self, _curr) == NULL_NODE_ID);
        return isSingleNode || !isNullNode;
    }

    function getNext(SpottedData storage self, uint256 _curr) public view returns (uint256) {
        return self.dll[_curr].next;
    }

    function getPrev(SpottedData storage self, uint256 _curr) public view returns (uint256) {
        return self.dll[_curr].prev;
    }

    function getStart(SpottedData storage self) public view returns (uint256) {
        return getNext(self, NULL_NODE_ID);
    }

    function getEnd(SpottedData storage self) public view returns (uint256) {
        return getPrev(self, NULL_NODE_ID);
    }

    /**
  * @dev Inserts a new node between _prev and _next. When inserting a node already existing in 
  the list it will be automatically removed from the old position.
  * @param _prev the node which _new will be inserted after
  * @param _curr the id of the new node being inserted
  * @param _next the node which _new will be inserted before
  */
    function insert(
        SpottedData storage self,
        uint256 _prev,
        uint256 _curr,
        uint256 _next
    ) public {
        require(_curr != NULL_NODE_ID, "error: could not insert, 1");

        remove(self, _curr);

        require(_prev == NULL_NODE_ID || contains(self, _prev), "error: could not insert, 2");
        require(_next == NULL_NODE_ID || contains(self, _next), "error: could not insert, 3");

        require(getNext(self, _prev) == _next, "error: could not insert, 4");
        require(getPrev(self, _next) == _prev, "error: could not insert, 5");

        self.dll[_curr].prev = _prev;
        self.dll[_curr].next = _next;

        self.dll[_prev].next = _curr;
        self.dll[_next].prev = _curr;
    }

    function remove(SpottedData storage self, uint256 _curr) public {
        if (!contains(self, _curr)) {
            return;
        }

        uint256 next = getNext(self, _curr);
        uint256 prev = getPrev(self, _curr);

        self.dll[next].prev = prev;
        self.dll[prev].next = next;

        delete self.dll[_curr];
    }
}

interface IParametersManager {
    // -------------- GETTERS : GENERAL --------------------
    function getMaxTotalWorkers() external view returns (uint256);

    function getVoteQuorum() external view returns (uint256);

    function get_MAX_UPDATE_ITERATIONS() external view returns (uint256);

    function get_MAX_CONTRACT_STORED_BATCHES() external view returns (uint256);

    function get_MAX_SUCCEEDING_NOVOTES() external view returns (uint256);

    function get_NOVOTE_REGISTRATION_WAIT_DURATION() external view returns (uint256);

    // -------------- GETTERS : ADDRESSES --------------------
    function getStakeManager() external view returns (address);

    function getRepManager() external view returns (address);

    function getAddressManager() external view returns (address);

    function getRewardManager() external view returns (address);

    function getArchivingSystem() external view returns (address);

    function getSpottingSystem() external view returns (address);

    function getComplianceSystem() external view returns (address);

    function getIndexingSystem() external view returns (address);

    function getsFuelSystem() external view returns (address);

    function getExordeToken() external view returns (address);

    // -------------- GETTERS : SPOTTING --------------------
    function get_SPOT_DATA_BATCH_SIZE() external view returns (uint256);

    function get_SPOT_MIN_STAKE() external view returns (uint256);

    function get_SPOT_MIN_CONSENSUS_WORKER_COUNT() external view returns (uint256);

    function get_SPOT_MAX_CONSENSUS_WORKER_COUNT() external view returns (uint256);

    function get_SPOT_COMMIT_ROUND_DURATION() external view returns (uint256);

    function get_SPOT_REVEAL_ROUND_DURATION() external view returns (uint256);

    function get_SPOT_MIN_REP_SpotData() external view returns (uint256);

    function get_SPOT_MIN_REWARD_SpotData() external view returns (uint256);

    function get_SPOT_MIN_REP_DataValidation() external view returns (uint256);

    function get_SPOT_MIN_REWARD_DataValidation() external view returns (uint256);

    function get_SPOT_INTER_ALLOCATION_DURATION() external view returns (uint256);

    function get_SPOT_TOGGLE_ENABLED() external view returns (bool);

    function get_SPOT_TIMEFRAME_DURATION() external view returns (uint256);

    function get_SPOT_GLOBAL_MAX_SPOT_PER_PERIOD() external view returns (uint256);

    function get_SPOT_MAX_SPOT_PER_USER_PER_PERIOD() external view returns (uint256);

    function get_SPOT_NB_TIMEFRAMES() external view returns (uint256);
}

interface IStakeManager {
    function ProxyStakeAllocate(uint256 _StakeAllocation, address _stakeholder) external returns (bool);

    function ProxyStakeDeallocate(uint256 _StakeToDeallocate, address _stakeholder) external returns (bool);

    function AvailableStakedAmountOf(address _stakeholder) external view returns (uint256);

    function AllocatedStakedAmountOf(address _stakeholder) external view returns (uint256);
}

interface IRepManager {
    function mintReputationForWork(
        uint256 _amount,
        address _beneficiary,
        bytes32
    ) external returns (bool);

    function burnReputationForWork(
        uint256 _amount,
        address _beneficiary,
        bytes32
    ) external returns (bool);
}

interface IRewardManager {
    function ProxyAddReward(uint256 _RewardsAllocation, address user_) external returns (bool);
}

interface IAddressManager {
    function isMasterOf(address _master, address _address) external returns (bool);

    function isSubWorkerOf(address _master, address _address) external returns (bool);

    function AreMasterSubLinked(address _master, address _address) external returns (bool);

    function getMasterSubs(address _master) external view returns (address);

    function getMaster(address _worker) external view returns (address);

    function FetchHighestMaster(address _worker) external view returns (address);
}

interface IFollowingSystem {
    function Ping(uint256 CheckedBatchId) external;

    function TriggerUpdate(uint256 iter) external;
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomAllocator.sol";

/**
* @title WorkSystem Spot v1.3.4a
* @author Mathias Dail - CTO @ Exorde Labs
*/
contract DataSpotting is Ownable, RandomAllocator {
    // ============ EVENTS ============
    event _SpotSubmitted(uint256 indexed DataID, string file_hash, string URL_domain, address indexed sender);
    event _SpotCheckCommitted(uint256 indexed DataID, uint256 numTokens, address indexed voter);
    event _SpotCheckRevealed(
        uint256 indexed DataID,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 indexed choice,
        address indexed voter
    );
    event _BatchValidated(uint256 indexed DataID, string file_hash, bool isVotePassed);
    event _WorkAllocated(uint256 indexed batchID, address worker);
    event _WorkerRegistered(address indexed worker, uint256 timestamp);
    event _WorkerUnregistered(address indexed worker, uint256 timestamp);
    event _StakeAllocated(uint256 numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint256 numTokens, address indexed voter);
    event _TokensRescued(uint256 indexed DataID, address indexed voter);
    event _DataBatchDeleted(uint256 indexed batchID);    
    event ParametersUpdated(address parameters);

    event BytesFailure(bytes bytesFailure);

    // ============ LIBRARIES ============
    // using AttributeStore for AttributeStore.SpottedData;
    using DLL for DLL.SpottedData;

    // ============ DATA STRUCTURES ============
    // ------ Spot-flow related structure

    struct TimeframeCounter {
        uint256 timestamp;
        uint256 counter;
    }

    enum DataStatus {
        TBD,
        APPROVED,
        REJECTED,
        FLAGGED
    }

    // ------ Worker State Structure
    struct WorkerState {
        uint256 allocated_work_batch;
        uint256 succeeding_novote_count;
        uint256 last_interaction_date;
        bool registered;
        bool unregistration_request;
        uint256 registration_date;
        uint256 allocated_batch_counter;
        uint256 majority_counter;
        uint256 minority_counter;
    }

    // ------ Data batch Structure
    struct BatchMetadata {
        uint256 start_idx;
        uint256 counter;
        uint256 uncommited_workers;
        uint256 unrevealed_workers;
        bool complete;
        bool checked;
        bool allocated_to_work;
        uint256 commitEndDate; // expiration date of commit period for poll
        uint256 revealEndDate; // expiration date of reveal period for poll
        uint256 votesFor; // tally of spot-check-votes supporting proposal
        uint256 votesAgainst; // tally of spot-check-votes countering proposal
        string batchIPFSfile; // to be updated during SpotChecking
        uint256 item_count;
        DataStatus status; // state of the vote
    }

    // ------ Atomic Data Structure
    struct SpottedData {
        string ipfs_hash; // expiration date of commit period for SpottedData
        address author; // author of the proposal
        uint256 timestamp; // expiration date of commit period for SpottedData
        uint256 item_count;
        string URL_domain; // URL domain
        string extra; // extra_data
        DataStatus status; // state of the vote
    }

    // ====================================
    //        GLOBAL STATE VARIABLES
    // ====================================

    // ------ Spotting input flow management
    uint256 public LastAllocationTime = 0;
    uint256 constant NB_TIMEFRAMES = 15;
    uint256 constant MAX_MASTER_DEPTH = 3;
    TimeframeCounter[NB_TIMEFRAMES] public GlobalSpotFlowManager;
    TimeframeCounter[NB_TIMEFRAMES] public ItemFlowManager;

    // ------ User (workers) Submissions & Commitees Related Structures
    mapping(address => mapping(uint256 => bool)) public UserChecksCommits; 
    // indicates whether an address committed a spot-check-vote for this poll
    mapping(address => mapping(uint256 => bool)) public UserChecksReveals; 
    // indicates whether an address revealed a spot-check-vote for this poll
    mapping(uint256 => mapping(address => uint256)) public UserVotes; 
    // maps DataID -> user addresses ->  vote option
    mapping(uint256 => mapping(address => string)) public UserNewFiles; 
    // maps DataID -> user addresses -> ipfs string -> counter
    mapping(uint256 => mapping(address => uint256)) public UserBatchCounts; 
    // maps DataID -> user addresses -> ipfs string -> counter
    mapping(uint256 => mapping(address => string)) public UserBatchFrom; 
    // maps DataID -> user addresses -> ipfs string -> counter
    mapping(address => uint256[]) public UserSubmissions; 
    // maps user's Addresses to DataIDs they submitted

    // ------ Backend Data Stores
    mapping(address => DLL.SpottedData) dllMap;
    // AttributeStore.SpottedData store;
    mapping(bytes32 => uint256) store;
    mapping(uint256 => SpottedData) public SpotsMapping; // maps DataID to SpottedData struct
    mapping(uint256 => BatchMetadata) public DataBatch; // refers to SpottedData indices

    // ------ Worker & Stake related structure
    mapping(address => WorkerState) public WorkersState;
    address[] public AllWorkersList;
    mapping(address => bool) public IsWorkerSeen; 
    mapping(address => TimeframeCounter[NB_TIMEFRAMES]) public WorkersSpotFlowManager;
    mapping(address => uint256) public SystemStakedTokenBalance; // maps user's address to voteToken balance

    // ------ Worker management structures
    mapping(uint256 => address[]) public WorkersPerBatch;
    address[] public availableWorkers;
    address[] public busyWorkers;
    address[] public toUnregisterWorkers;
    mapping(address => bool) public isAvailableWorker;
    mapping(address => bool) public isBusyWorker;
    mapping(address => bool) public isToUnregisterWorker;
    mapping(address => uint256) public availableWorkersIndex;
    mapping(address => uint256) public busyWorkersIndex;
    mapping(address => uint256) public toUnregisterWorkersIndex;
    mapping(uint256 => uint256) public BatchCommitedVoteCount; 
    mapping(uint256 => uint256) public BatchRevealedVoteCount; 

    uint256 public LastRandomSeed = 0;

    // ------ Processes counters
    uint256 public DataNonce = 0;
    // -- Batches Counters
    uint256 public BatchDeletionCursor = 1;
    uint256 public LastBatchCounter = 1;
    uint256 public BatchCheckingCursor = 1;
    uint256 public AllocatedBatchCursor = 1;

    // ------ Statistics related counters
    uint256 public AllTxsCounter = 0;
    uint256 public AllItemCounter = 0;
    uint256 public AcceptedBatchsCounter = 0;
    uint256 public RejectedBatchsCounter = 0;
    uint256 public NotCommitedCounter = 0;
    uint256 public NotRevealedCounter = 0;

    // ------ Vote related
    
    uint256 constant APPROVAL_VOTE_MAPPING_  = 1;
    uint256 constant MAX_WORKER_ALLOCATED_PER_BATCH = 50;

    // ------------ Testnet related

    bool public InstantSpotRewards = true;
    bool public InstantRevealRewards = true;
    uint256 public InstantSpotRewardsDivider = 5;
    uint256 public InstantRevealRewardsDivider = 2;

    uint256 public MaxPendingDataBatchCount = 1000;
    uint256 public SPOT_FILE_SIZE = 100;
    uint256 public GAS_LEFT_LIMIT = 1000000;

    bool public STAKING_REQUIREMENT_TOGGLE_ENABLED = false;
    bool public TRIGGER_WITH_SPOTDATA_TOGGLE_ENABLED = false;
    bool public STRICT_RANDOMNESS_REQUIREMENT = false;
    bool public VALIDATE_ON_LAST_REVEAL = true;

    bool public FORCE_VALIDATE_BATCH_FILE = true;

    // ------ Addresses & Interfaces
    IERC20 public token;
    IParametersManager public Parameters;

    // ================================================================================
    //                             Constructor
    // ================================================================================
    
    /**
  * @dev Initializer. Can only be called once.
  */
    constructor(address EXDT_token_) {
        require(address(EXDT_token_) != address(0));
        token = IERC20(EXDT_token_);
    }

    // ================================================================================
    //                             Testnet Management & Administration
    // ================================================================================

    /**
     * @dev Destroy Contract, important to release storage space if critical
     */
    function destroyContract() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    /**
   * @notice Updates Parameters Manager
   * @param addr address of the Parameter Contract
  */
    function updateParametersManager(address addr) public onlyOwner {        
        require(addr != address(0), "addr must be non zero");
        Parameters = IParametersManager(addr);
        emit ParametersUpdated(addr);
    }


    /**
  * @notice Enable or disable Required Staking for participation 
  * @param toggle_ boolean
  */
    function toggleRequiredStaking(bool toggle_) public onlyOwner {
        STAKING_REQUIREMENT_TOGGLE_ENABLED = toggle_;
    }

    /**
  * @notice Enable or disable Triggering Updates when Spotting Data
  * @param toggle_ boolean
  */
    function toggleTriggerSpotData(bool toggle_) public onlyOwner {
        TRIGGER_WITH_SPOTDATA_TOGGLE_ENABLED = toggle_;
    }

    /**
  * @notice Enable or disable Strict Randomness
  * @param toggle_ boolean
  */
    function toggleStrictRandomness(bool toggle_) public onlyOwner {
        STRICT_RANDOMNESS_REQUIREMENT = toggle_;
    }

    /**
  * @notice Enable or disable Automatic Batch Validation when last to reveal
  * @param toggle_ boolean
  */
    function toggleValidateLastReveal(bool toggle_) public onlyOwner {
        VALIDATE_ON_LAST_REVEAL = toggle_;
    }

    /**
  * @notice Enable or disable Forcing the Validation of a Batch File in some conditions
  * @param toggle_ boolean
  */
    function toggleForceValidateBatchFile(bool toggle_) public onlyOwner {
        FORCE_VALIDATE_BATCH_FILE = toggle_;
    }

    // ================================================================================
    //                             ADMIN Updaters
    // ================================================================================

    /**
  * @notice Enable or disable instant rewards when SpottingData (Testnet)
  * @param state_ boolean
  * @param divider_ base rewards divider
  */
    function updateInstantSpotRewards(bool state_, uint256 divider_) public onlyOwner {
        InstantSpotRewards = state_;
        InstantSpotRewardsDivider = divider_;
    }

    /**
  * @notice Enable or disable instant rewards when Revealing (Testnet)
  * @param state_ boolean
  * @param divider_ base rewards divider
  */
    function updateInstantRevealRewards(bool state_, uint256 divider_) public onlyOwner {
        InstantRevealRewards = state_;
        InstantRevealRewardsDivider = divider_;
    }

    /**
  * @notice update MaxPendingDataBatchCount, limiting the queue of data to validate
  * @param MaxPendingDataBatchCount_ max queue size
  */
    function updateMaxPendingDataBatch(uint256 MaxPendingDataBatchCount_) public onlyOwner {
        MaxPendingDataBatchCount = MaxPendingDataBatchCount_;
    }


    /**
  * @notice update file_size_, the spot atomic file size
  * @param file_size_ spot atomic file size
  */
    function updateSpotFileSize(uint256 file_size_) public onlyOwner {
        SPOT_FILE_SIZE = file_size_;
    }

    /**
  * @notice update Gas Left limit, limiting the validation loops iterations
  * @param new_limit_ gas limit in wei
  */
    function updateGasLeftLimit(uint256 new_limit_) public onlyOwner {
        GAS_LEFT_LIMIT = new_limit_;
    }

    // ================================================================================
    //                             Library Related
    // ================================================================================

    /**
  * @notice getAttribute from UUID and attrName
  * @param _UUID unique identifier
  * @param _attrName name of the attribute
  */
    function getAttribute(bytes32 _UUID, string memory _attrName) public view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(_UUID, _attrName));
        return store[key];
    }

    /**
  * @notice setAttribute from UUID , attrName & attrVal
  * @param _UUID unique identifier
  * @param _attrName name of the attribute
  * @param _attrVal value of the attribute
  */
    function setAttribute(
        bytes32 _UUID,
        string memory _attrName,
        uint256 _attrVal
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(_UUID, _attrName));
        store[key] = _attrVal;
    }

    // ================================================================================
    //                              sFuel (eth) Auto Top Up system
    // ================================================================================

    /**
  * @notice Refill the msg.sender with sFuel. Skale gasless "gas station network" equivalent
  */
    function _retrieveSFuel() internal {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        address sFuelAddress;
        sFuelAddress = Parameters.getsFuelSystem();
        require(sFuelAddress != address(0), "sFuel: null Address Not Valid");
        (bool success1, ) = sFuelAddress.call(abi.encodeWithSignature("retrieveSFuel(address)", payable(msg.sender)));
        (bool success2, ) = sFuelAddress.call(
            abi.encodeWithSignature("retrieveSFuel(address payable)", payable(msg.sender))
        );
        require((success1 || success2), "receiver rejected _retrieveSFuel call");
    }

    // ================================================================================
    //                         WORKER REGISTRATION & LOBBY MANAGEMENT
    // ================================================================================

    /**
  * @notice Checks if Worker is Available
  * @param _worker worker address
  */
    function isInAvailableWorkers(address _worker) public view returns (bool) {
        return isAvailableWorker[_worker];
    }

    /**
  * @notice Checks if Worker is Busy
  * @param _worker worker address
  */
    function isInBusyWorkers(address _worker) public view returns (bool) {
        return isBusyWorker[_worker];
    }

    /**
  * @notice Checks if Worker in the "to log off" list
  */
    function IsInLogoffList(address _worker) public view returns (bool) {
        return isToUnregisterWorker[_worker];
    }

    uint256 REMOVED_WORKER_INDEX_VALUE = 9999999999;

    /**
  * @notice Pop _worker from the Available workers
  */
    function PopFromAvailableWorkers(address _worker) internal {
        if (isAvailableWorker[_worker]) {
            uint256 PreviousIndex = availableWorkersIndex[_worker];
            address SwappedWorkerAtIndex = availableWorkers[availableWorkers.length - 1];

            // Update Worker State
            isAvailableWorker[_worker] = false;
            availableWorkersIndex[_worker] = REMOVED_WORKER_INDEX_VALUE; // reset available worker index

            if (availableWorkers.length >= 2) {
                availableWorkers[PreviousIndex] = SwappedWorkerAtIndex; // swap last worker to this new position
                // Update moved item Index
                availableWorkersIndex[SwappedWorkerAtIndex] = PreviousIndex;
            }

            availableWorkers.pop(); // pop last worker
        }
    }

    /**
  * @notice Pop worker from the Busy workers
  */
    function PopFromBusyWorkers(address _worker) internal {
        if (isBusyWorker[_worker]) {
            uint256 PreviousIndex = busyWorkersIndex[_worker];
            address SwappedWorkerAtIndex = busyWorkers[busyWorkers.length - 1];

            // Update Worker State
            isBusyWorker[_worker] = false;
            busyWorkersIndex[_worker] = REMOVED_WORKER_INDEX_VALUE; // reset available worker index

            if (busyWorkers.length >= 2) {
                busyWorkers[PreviousIndex] = SwappedWorkerAtIndex; // swap last worker to this new position
                // Update moved item Index
                busyWorkersIndex[SwappedWorkerAtIndex] = PreviousIndex;
            }

            busyWorkers.pop(); // pop last worker
        }
    }

    function PopFromLogoffList(address _worker) internal {
        if (isToUnregisterWorker[_worker]) {
            uint256 PreviousIndex = toUnregisterWorkersIndex[_worker];
            address SwappedWorkerAtIndex = toUnregisterWorkers[toUnregisterWorkers.length - 1];

            // Update Worker State
            isToUnregisterWorker[_worker] = false;
            toUnregisterWorkersIndex[_worker] = REMOVED_WORKER_INDEX_VALUE; // reset available worker index

            if (busyWorkers.length >= 2) {
                toUnregisterWorkers[PreviousIndex] = SwappedWorkerAtIndex; // swap last worker to this new position
                // Update moved item Index
                toUnregisterWorkersIndex[SwappedWorkerAtIndex] = PreviousIndex;
            }

            toUnregisterWorkers.pop(); // pop last worker
        }
    }

    function PushInAvailableWorkers(address _worker) internal {
        if (!isInAvailableWorkers(_worker)) {
            availableWorkers.push(_worker);
            // Update Worker State
            isAvailableWorker[_worker] = true;
            availableWorkersIndex[_worker] = availableWorkers.length - 1;
        }
    }

    function PushInBusyWorkers(address _worker) internal {
        if (!isInBusyWorkers(_worker)) {
            busyWorkers.push(_worker);
            // Update Worker State
            isBusyWorker[_worker] = true;
            busyWorkersIndex[_worker] = busyWorkers.length - 1;
        }
    }

    /**
     * @notice Check if worker allocated to batch _DataBatchId
                There is no loop break here, because the number of 
                allocated workers per batch is always low (< 50). 
                This loop can be considered O(1).
     * @param _DataBatchId _DataBatchId
     * @param _worker address
     * @return bool if worker allocated to batch
     */
    function isWorkerAllocatedToBatch(uint256 _DataBatchId, address _worker) public view returns (bool) {
        bool found = false;
        address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
        for (uint256 i = 0; i < allocated_workers.length; i++) {
            if (allocated_workers[i] == _worker) {
                found = true;
                break;
            }
        }
        return found;
    }

    /* 
        Select Address for a worker address, between itself and a potential Master Address    
    Crawl up the tree of master (depth can be max 3: worker -> master-worker -> main address)
    */
    function SelectAddressForUser(address _worker, uint256 _TokensAmountToAllocate) public view returns (address) {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        require(Parameters.getAddressManager() != address(0), "AddressManager is null in Parameters");
        require(Parameters.getStakeManager() != address(0), "StakeManager is null in Parameters");
        IStakeManager _StakeManager = IStakeManager(Parameters.getStakeManager());
        IAddressManager _AddressManager = IAddressManager(Parameters.getAddressManager());

        address _SelectedAddress = _worker;
        address _CurrentAddress = _worker;

        for (uint256 i = 0; i < MAX_MASTER_DEPTH; i++) {
            // check if _CurrentAddress has enough available stake
            uint256 _CurrentAvailableStake = _StakeManager.AvailableStakedAmountOf(_CurrentAddress);

            // Case 1 : the _CurrentAddress has enough staked in the system already, then good.
            if (SystemStakedTokenBalance[_CurrentAddress] >= _TokensAmountToAllocate) {
                // Found enough Staked in the system already, return this address
                _SelectedAddress = _CurrentAddress;
                break;
            }
            // Case 2 : the _CurrentAddress has partially enough staked in the system already
            else if (
                SystemStakedTokenBalance[_CurrentAddress] <= _TokensAmountToAllocate &&
                SystemStakedTokenBalance[_CurrentAddress] > 0
            ) {
                uint256 remainderAmountToAllocate = _TokensAmountToAllocate
                    - SystemStakedTokenBalance[_CurrentAddress] ;
                if (_CurrentAvailableStake >= remainderAmountToAllocate) {
                    // There is enough in the AvailableStake to allocate, return this address
                    _SelectedAddress = _CurrentAddress;
                    break;
                }
            }
            // Case 3 : the _CurrentAddress enough to allocate on StakeManager for the given amount
            if (_CurrentAvailableStake >= _TokensAmountToAllocate) {
                // There is enough in the AvailableStake to allocate, return this address
                _SelectedAddress = _CurrentAddress;
                break;
            }

            _CurrentAddress = _AddressManager.getMaster(_CurrentAddress);

            if (_CurrentAddress == address(0)) {
                break; // quit the loop if we reached a "top" in the tree search
            }
        }

        return _SelectedAddress;
    }

    function IsAddressKicked(address user_) public view returns(bool status){
        bool status_ = false;
        WorkerState storage worker_state = WorkersState[user_];
        if(     (   worker_state.succeeding_novote_count >= Parameters.get_MAX_SUCCEEDING_NOVOTES() 
                && ((block.timestamp - worker_state.registration_date) <
                    Parameters.get_NOVOTE_REGISTRATION_WAIT_DURATION()))
        )
        {
            status_ = true;
        }
        return status_;
    }

    function AmIKicked() public view returns(bool status){        
        return IsAddressKicked(msg.sender);
    }

    /* Register worker (online) */
    function RegisterWorker() public {
        WorkerState storage worker_state = WorkersState[msg.sender];

        if ( !IsWorkerSeen[msg.sender] ){
            AllWorkersList.push(msg.sender);
            IsWorkerSeen[msg.sender] = true;
        }
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        require(
            (availableWorkers.length + busyWorkers.length) < Parameters.getMaxTotalWorkers(),
            "Maximum registered workers already"
        );
        require(!worker_state.registered, "Worker is already registered (1)");
        require(!isInAvailableWorkers(msg.sender) && !isInBusyWorkers(msg.sender), "Worker is already registered (2)");
        // require worker to NOT have NOT VOTED MAX_SUCCEEDING_NOVOTES times in a row.
        require(
            !(worker_state.succeeding_novote_count >= Parameters.get_MAX_SUCCEEDING_NOVOTES() &&
                (block.timestamp - worker_state.registration_date) <
                Parameters.get_NOVOTE_REGISTRATION_WAIT_DURATION()),
            "Address kicked temporarily from participation"
        );

        // ---  Master/SubWorker Stake Management
        //_numTokens The number of tokens to be committed towards the target SpottedData
        if (STAKING_REQUIREMENT_TOGGLE_ENABLED) {
            uint256 _numTokens = Parameters.get_SPOT_MIN_STAKE();
            address _selectedAddress = SelectAddressForUser(msg.sender, _numTokens);
            // if tx sender has a master, then interact with his master's stake, or himself
            if (SystemStakedTokenBalance[_selectedAddress] < _numTokens) {
                uint256 remainder = _numTokens - SystemStakedTokenBalance[_selectedAddress];
                requestAllocatedStake(remainder, _selectedAddress);
            }
        }
        //////////////////////////////////
        PushInAvailableWorkers(msg.sender);

        worker_state.registered = true;
        worker_state.unregistration_request = false;
        worker_state.registration_date = block.timestamp;
        worker_state.succeeding_novote_count = 0; // reset the novote counter

        AllTxsCounter += 1;
        _retrieveSFuel();
        emit _WorkerRegistered(msg.sender, block.timestamp);
    }

    /* Unregister worker (offline) */
    function UnregisterWorker() public {
        WorkerState storage worker_state = WorkersState[msg.sender];
        require(worker_state.registered, "Worker is not registered so can't unregister");
        if (
            worker_state.allocated_work_batch != 0 &&
            !worker_state.unregistration_request &&
            !IsInLogoffList(msg.sender)
        ) {
            //////////////////////////////////
            worker_state.unregistration_request = true;
            toUnregisterWorkers.push(msg.sender);
            isToUnregisterWorker[msg.sender] = true;
        }
        if (worker_state.allocated_work_batch == 0) {
            // only unregister a worker if he is not working
            //////////////////////////////////
            PopFromAvailableWorkers(msg.sender);
            PopFromBusyWorkers(msg.sender);
            PopFromLogoffList(msg.sender);
            worker_state.last_interaction_date = block.timestamp;
            isToUnregisterWorker[msg.sender] = false;
            worker_state.registered = false;
            emit _WorkerUnregistered(msg.sender, block.timestamp);
        }

        AllTxsCounter += 1;
        _retrieveSFuel();
    }

    function processLogoffRequests(uint256 n_iteration) internal {
        uint256 iteration_count = Math.min(n_iteration, toUnregisterWorkers.length);
        for (uint256 i = 0; i < iteration_count; i++) {
            address worker_addr_ = toUnregisterWorkers[i];
            WorkerState storage worker_state = WorkersState[worker_addr_];
            if (worker_state.allocated_work_batch == 0) {
                /////////////////////////////////
                worker_state.registered = false;
                worker_state.unregistration_request = false;
                PopFromAvailableWorkers(worker_addr_);
                PopFromBusyWorkers(worker_addr_);
                isToUnregisterWorker[worker_addr_] = false;
                emit _WorkerUnregistered(worker_addr_, block.timestamp);
            }
        }
        if(toUnregisterWorkers.length == 0){
            delete toUnregisterWorkers;
        }
    }

    // ================================================================================
    //                             Data Deletion Function
    // ================================================================================

    /**
  * @notice Delete Data in a rolling window
  */
    function deleteOldData() internal {
        // Rolling delete of previous data
        uint256 BatchesToDeleteCount = BatchCheckingCursor - BatchDeletionCursor;
        // Here the amount of iterations is capped by get_MAX_UPDATE_ITERATIONS
        if (BatchesToDeleteCount > Parameters.get_MAX_CONTRACT_STORED_BATCHES()) {
            for (uint256 i = 0; i < Math.min(Parameters.get_MAX_UPDATE_ITERATIONS(), BatchesToDeleteCount); i++) {
                // First Delete Atomic Data composing the Batch, from start to end indices
                uint256 start_batch_idx = DataBatch[BatchDeletionCursor].start_idx;
                uint256 end_batch_idx = DataBatch[BatchDeletionCursor].start_idx +
                    DataBatch[BatchDeletionCursor].counter;
                for (uint256 l = start_batch_idx; l < end_batch_idx; l++) {
                    delete SpotsMapping[l]; // delete SpotsMapping at index l
                }
                emit _DataBatchDeleted(BatchDeletionCursor);
            }
        }
    }

    // ================================================================================
    //                             Trigger State Update : Public
    // ================================================================================


    /**
  * @notice Trigger potential Data Batches Validations & Work Allocations
  * @param iteration_count max number of iterations
  */
    function TriggerUpdate(uint256 iteration_count) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        // Update the Spot Flow System
        updateGlobalSpotFlow();
        updateItemCount();
        // Delete old data if needed
        deleteOldData();
        TriggerValidation(iteration_count);
        // Log off waiting users first
        processLogoffRequests(iteration_count);
        TriggerAllocations(iteration_count);
        _retrieveSFuel();
    }

    /**
  * @notice Trigger at most iteration_count Work Allocations (N workers on a Batch)
  * @param iteration_count max number of iterations
  */
    function TriggerAllocations(uint256 iteration_count) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        // Log off waiting users first
        processLogoffRequests(iteration_count);
        // Then iterate as much as possible in the batches.
        if ((LastRandomSeed != getRandom()) || !STRICT_RANDOMNESS_REQUIREMENT) {
            for (uint256 i = 0; i < iteration_count; i++) {
                bool progress = false;
                // IF CURRENT BATCH IS COMPLETE AND NOT ALLOCATED TO WORKERS TO BE CHECKED, THEN ALLOCATE!
                if (
                    DataBatch[AllocatedBatchCursor].allocated_to_work != true &&
                    availableWorkers.length >= Parameters.get_SPOT_MIN_CONSENSUS_WORKER_COUNT() &&
                    DataBatch[AllocatedBatchCursor].complete
                ) {
                    AllocateWork();
                    progress = true;
                }
                if (!progress) {
                    // break from the loop if no more progress
                    break;
                }
            }
        }
        _retrieveSFuel();
    }

    /**
  * @notice Trigger at most iteration_count Ended DataBatch validations
  * @param iteration_count max number of iterations
  */
    function TriggerValidation(uint256 iteration_count) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        uint256 PrevCursor = BatchCheckingCursor;
        for (uint256 i = 0; i < iteration_count; i++) {
            uint256 CurrentCursor = PrevCursor + i;
            // IF CURRENT BATCH IS ALLOCATED TO WORKERS AND VOTE HAS ENDED, THEN CHECK IT & MOVE ON!
            if (
                DataBatch[CurrentCursor].allocated_to_work &&
                (DataEnded(CurrentCursor) || (DataBatch[CurrentCursor].unrevealed_workers == 0))
            )  {	
                // check if the batch is already validated	
                if (!DataBatch[CurrentCursor].checked) {	
                    ValidateDataBatch(CurrentCursor);	
                }	
                // increment BatchCheckingCursor if possible	
                if (CurrentCursor == BatchCheckingCursor + 1) {	
                    BatchCheckingCursor = BatchCheckingCursor + 1;	
                }	
            }
        }
    }

    /**
  * @notice Checks if two strings are equal
  * @param _a string
  * @param _b string
  */
    function AreStringsEqual(string memory _a, string memory _b) public pure returns (bool) {
        if (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b))) {
            return true;
        } else {
            return false;
        }
    }

    
    // ================================================================================
    //                             Validate Data Batch
    // ================================================================================


    /**
  * @notice Trigger the validation of DataBatch
  * @param _DataBatchId Integer identifier associated with target SpottedData
  */
    function ValidateDataBatch(uint256 _DataBatchId) internal {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        require(Parameters.getAddressManager() != address(0), "AddressManager is null in Parameters");
        require(Parameters.getRepManager() != address(0), "RepManager is null in Parameters");
        require(Parameters.getRewardManager() != address(0), "RewardManager is null in Parameters");
        require(
            DataEnded(_DataBatchId) || (DataBatch[_DataBatchId].unrevealed_workers == 0),
            "_DataBatchId has not ended, or not every voters have voted"
        ); // votes needs to be closed
        require(!DataBatch[_DataBatchId].checked, 
            "_DataBatchId is already validated"); // votes needs to be closed

        address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
        string[] memory proposedNewFiles = new string[](allocated_workers.length);
        uint256[] memory proposedBatchCounts = new uint256[](allocated_workers.length);

        // -------------------------------------------------------------
        // GATHER USER SUBMISSIONS AND VOTE INPUTS BEFORE ASSESSMENT

        for (uint256 i = 0; i < allocated_workers.length; i++) {
            address worker_addr_ = allocated_workers[i];
            string memory worker_proposed_new_file_ = UserNewFiles[_DataBatchId][worker_addr_];
            uint256 worker_proposed_new_count_ = UserBatchCounts[_DataBatchId][worker_addr_];
            proposedNewFiles[i] = worker_proposed_new_file_;
            proposedBatchCounts[i] = worker_proposed_new_count_;
        }

        // -------------------------------------------------------------
        // MAJORITY QUORUM COMPUTATION
        uint256 majority_min_count = Math.max((allocated_workers.length * Parameters.getVoteQuorum()) / 100, 1);

        // GET THE MAJORITY NEW HASH IPFS FILE
        string memory majorityNewFile = ""; //take first file by default, just in case
        for (uint256 k = 0; k < proposedNewFiles.length; k++) {
            // count if this given New File is submitted by a majority
            uint256 counter = 0;
            for (uint256 l = 0; l < proposedNewFiles.length; l++) {
                if (AreStringsEqual(proposedNewFiles[k], proposedNewFiles[l])) {
                    counter += 1;
                    if (counter >= majority_min_count) {
                        break;
                    }
                }
            }
            if (counter >= majority_min_count) {
                majorityNewFile = proposedNewFiles[k];
                break;
            }
        }

        // GET THE MAJORITY BATCH COUNT
        uint256 majorityBatchCount = 0; //take first file by default, just in case
        for (uint256 k = 0; k < proposedBatchCounts.length; k++) {
            // count if this given New File is submitted by a majority
            uint256 counter = 0;
            for (uint256 l = 0; l < proposedBatchCounts.length; l++) {
                if (proposedBatchCounts[k] == proposedBatchCounts[l]) {
                    counter += 1;
                    if (counter >= majority_min_count) {
                        break;
                    }
                }
            }
            if (counter >= majority_min_count) {
                majorityBatchCount = proposedBatchCounts[k];
                break;
            }
        }

        // -------------------------------------------------------------
        // ASSESS VOTE RESULT AND REWARD USERS ACCORDINGLY
        // IMPORTANT: AND IF MAJORITY EXISTS
        bool isCheckPassed = isPassed(_DataBatchId) &&
            (!AreStringsEqual(majorityNewFile, "")) &&
            (majorityBatchCount != 0);

        // Force the protocol to validate a batch with at least 1 vote (and 1 non-null file hash)
        if (FORCE_VALIDATE_BATCH_FILE) {
            BatchMetadata memory batch_ = DataBatch[_DataBatchId];
            if (batch_.votesFor > 0) {
                // FORCE PASS ON BATCH
                isCheckPassed = true;
            }

            if (AreStringsEqual(majorityNewFile, "")) {
                //If majorityNewFile is null, find a submitted file to replace it
                for (uint256 i = 0; i < allocated_workers.length; i++) {
                    if (!UserChecksReveals[allocated_workers[i]][_DataBatchId]) {
                        continue; // if user has not even voted, skip.
                    }
                    // if majorityNewFile was null, find a replacement
                    if (!AreStringsEqual(proposedNewFiles[i], "")) {
                        // REPLACE MAJORITY BATCH FILE
                        majorityNewFile = proposedNewFiles[i];
                    }
                    //if majorityBatchCount was zero, find a replacement
                    if (majorityBatchCount == 0 && proposedBatchCounts[i] > 0) {
                        // REPLACE MAJORITY BATCH COUNT
                        majorityBatchCount = proposedBatchCounts[i];
                    }
                    if (!AreStringsEqual(majorityNewFile, "") && majorityBatchCount > 0) {
                        break;
                    }
                }
            }
        }

        // Failing case: make majorityBatchCount SPOT_FILE_SIZE for that case, for a minimum rewards.
        if (!isCheckPassed) {
            majorityBatchCount = SPOT_FILE_SIZE;
        } else {
            // Cap the Batch Count to [Maximum Nb of files in batch * SPOT_FILE_SIZE)] (there can't be more item)
            majorityBatchCount = Math.min(DataBatch[_DataBatchId].counter * SPOT_FILE_SIZE, majorityBatchCount);
        }


        for (uint256 i = 0; i < allocated_workers.length; i++) {
            address worker_addr_ = allocated_workers[i];
            uint256 worker_vote_ = UserVotes[_DataBatchId][worker_addr_];
            bool has_worker_voted_ = UserChecksReveals[worker_addr_][_DataBatchId];

            // Worker state update
            WorkerState storage worker_state = WorkersState[worker_addr_];

            // ------- if worker has indeed voted (commited & revealed)
            if (has_worker_voted_) {
                // mark that worker has completed job, no matter the reward

                WorkersState[worker_addr_].succeeding_novote_count = 0; // reset the novote counter
                // then assess if worker is in the majority to reward him
                if ((isCheckPassed && worker_vote_ == 1) || (!isCheckPassed && worker_vote_ != 1)) {
                    // vote 1 == OK, else = NOT OK, rejected
                    // reward worker if he voted like the majority

                    IAddressManager _AddressManager = IAddressManager(Parameters.getAddressManager());
                    IRepManager _RepManager = IRepManager(Parameters.getRepManager());
                    IRewardManager _RewardManager = IRewardManager(Parameters.getRewardManager());

                    address worker_master_addr_ = _AddressManager.FetchHighestMaster(worker_addr_);
                    if (majorityBatchCount > 0) {
                        require(
                            _RepManager.mintReputationForWork(
                                Parameters.get_SPOT_MIN_REP_DataValidation() * majorityBatchCount,
                                worker_master_addr_,
                                ""
                            ),
                            "could not reward REP in Validate, 1.a"
                        );
                        require(
                            _RewardManager.ProxyAddReward(
                                Parameters.get_SPOT_MIN_REWARD_DataValidation() * majorityBatchCount,
                                worker_master_addr_
                            ),
                            "could not reward token in Validate, 1.b"
                        );
                    }
                    worker_state.majority_counter += 1;
                } else {
                    worker_state.minority_counter += 1;
                }
            }
            // ------- if worker has not voted (never revealed)
            else {
                WorkersState[worker_addr_].succeeding_novote_count += 1;
                /// --- FORCE LOG OFF USER IF HAS NOT VOTED MULTIPLE TIMES IN A ROW
                if (WorkersState[worker_addr_].succeeding_novote_count >= Parameters.get_MAX_SUCCEEDING_NOVOTES()) {
                    worker_state.registered = false;
                    PopFromBusyWorkers(worker_addr_);
                    PopFromAvailableWorkers(worker_addr_);
                }
                //  if worker has revealed, he is available again (revealing releases a given worker)
                //  if worker has not revealed, then worker is still busy, pop him from Busy, back to Available
                if (worker_state.registered) {
                    // only if the worker is still registered
                    PopFromBusyWorkers(worker_addr_);
                    PushInAvailableWorkers(worker_addr_);
                }
                worker_state.allocated_work_batch = 0;
            }
        }
        // -------------------------------------------------------------
        // BATCH STATE UPDATE: mark it checked, final.
        DataBatch[_DataBatchId].checked = true;
        DataBatch[_DataBatchId].batchIPFSfile = majorityNewFile;
        DataBatch[_DataBatchId].item_count = majorityBatchCount;
        // -------------------------------------------------------------
        // IF THE DATA BLOCK IS ACCEPTED
        if (isCheckPassed) {
            // Reward Spotters involved in the Batch
            uint256 start_batch_idx = DataBatch[_DataBatchId].start_idx;
            uint256 end_batch_idx = DataBatch[_DataBatchId].start_idx + DataBatch[_DataBatchId].counter;

            // -------------------------------------------------------------
            // Rewards Spot Authors, one by one, for the batch
            for (uint256 l = start_batch_idx; l < end_batch_idx; l++) {
                address spot_author_ = SpotsMapping[l].author;
                IAddressManager _AddressManager = IAddressManager(Parameters.getAddressManager());
                IRepManager _RepManager = IRepManager(Parameters.getRepManager());
                IRewardManager _RewardManager = IRewardManager(Parameters.getRewardManager());
                address spot_author_master_ = _AddressManager.FetchHighestMaster(spot_author_);
                if (majorityBatchCount > 0) {
                    require(
                        _RepManager.mintReputationForWork(
                            Parameters.get_SPOT_MIN_REP_SpotData() * majorityBatchCount,
                            spot_author_master_,
                            ""
                        ),
                        "could not reward REP in ValidateDataBatch, 2.a"
                    );
                    require(
                        _RewardManager.ProxyAddReward(
                            Parameters.get_SPOT_MIN_REWARD_SpotData() * majorityBatchCount,
                            spot_author_master_
                        ),
                        "could not reward token in ValidateDataBatch, 2.b"
                    );
                }
            }
            // UPDATE BATCH STATE
            DataBatch[_DataBatchId].status = DataStatus.APPROVED;
            AcceptedBatchsCounter += 1;

            // SEND THIS BATCH TO THIS FollowingSystem
            require(Parameters.getComplianceSystem() != address(0), "ComplianceSystem null in Parameters Contract");
            IFollowingSystem _ComplianceSystem = IFollowingSystem(Parameters.getComplianceSystem());

            try _ComplianceSystem.Ping(_DataBatchId) {
                AllTxsCounter += 1;
            } catch (bytes memory err) {
                emit BytesFailure(err);
            }
        }
        // -------------------------------------------------------------
        // IF THE DATA BLOCK IS REJECTED
        else {
            DataBatch[_DataBatchId].status = DataStatus.REJECTED;
            RejectedBatchsCounter += 1;
        }
        // ---------------- GLOBAL STATE UPDATE ----------------
        AllTxsCounter += 1;
        AllItemCounter += DataBatch[_DataBatchId].item_count;
        ItemFlowManager[ItemFlowManager.length - 1].counter +=  DataBatch[_DataBatchId].item_count;
        updateItemCount();
        NotCommitedCounter += DataBatch[_DataBatchId].uncommited_workers;
        NotRevealedCounter += DataBatch[_DataBatchId].unrevealed_workers;


        emit _BatchValidated(_DataBatchId, majorityNewFile, isCheckPassed);
    }

    /**
  * @notice Allocate last data batch to be checked by K out N currently available workers.
  */
    function AllocateWork() internal {
        require(DataBatch[AllocatedBatchCursor].complete, "Can't allocate work, the current batch is not complete");
        require(
            !DataBatch[AllocatedBatchCursor].allocated_to_work,
            "Can't allocate work, the current batch is already allocated"
        );
        uint256 selected_k = Math.max(
            Math.min(availableWorkers.length, Parameters.get_SPOT_MAX_CONSENSUS_WORKER_COUNT()),
            Parameters.get_SPOT_MIN_CONSENSUS_WORKER_COUNT()
        );
        require(selected_k <= MAX_WORKER_ALLOCATED_PER_BATCH,  
        // this require check force the allocatedWorkers array to be capped in size
        "selected_k must be at most MAX_WORKER_ALLOCATED_PER_BATCH" );
        uint256 n = availableWorkers.length;

        if ((block.timestamp - LastAllocationTime) >= Parameters.get_SPOT_INTER_ALLOCATION_DURATION()) {
            ///////////////////////////// BATCH UPDATE STATE /////////////////////////////
            DataBatch[AllocatedBatchCursor].unrevealed_workers = selected_k;
            DataBatch[AllocatedBatchCursor].uncommited_workers = selected_k;
            uint256 _commitEndDate = block.timestamp + Parameters.get_SPOT_COMMIT_ROUND_DURATION();
            uint256 _revealEndDate = _commitEndDate + Parameters.get_SPOT_REVEAL_ROUND_DURATION();
            DataBatch[AllocatedBatchCursor].commitEndDate = _commitEndDate;
            DataBatch[AllocatedBatchCursor].revealEndDate = _revealEndDate;
            DataBatch[AllocatedBatchCursor].allocated_to_work = true;
            //////////////////////////////////////////////////////////////////////////////

            require(selected_k >= 1 && n >= 1, "Fail during allocation: not enough workers");
            uint256[] memory selected_workers_idx = random_selection(selected_k, n);
            address[] memory selected_workers_addresses = new address[](selected_workers_idx.length);

                // There is no loop break here, because the number of 
                // allocated workers per batch is always low (< 50). 
                // This loop can be considered O(1).

            for (uint256 i = 0; i < selected_workers_idx.length; i++) {
                selected_workers_addresses[i] = availableWorkers[selected_workers_idx[i]];
            }

            for (uint256 i = 0; i < selected_workers_idx.length; i++) {
                address selected_worker_ = selected_workers_addresses[i];
                WorkerState storage worker_state = WorkersState[selected_worker_];
                ///// worker swapping from available to busy, not to be picked again while working.
                PopFromAvailableWorkers(selected_worker_);
                PushInBusyWorkers(selected_worker_); //set worker as busy
                WorkersPerBatch[AllocatedBatchCursor].push(selected_worker_);
                ///// allocation
                worker_state.allocated_work_batch = AllocatedBatchCursor;
                worker_state.allocated_batch_counter += 1;
                emit _WorkAllocated(AllocatedBatchCursor, selected_worker_);
            }

            LastAllocationTime = block.timestamp;
            AllocatedBatchCursor += 1;
            LastRandomSeed = getRandom();
            AllTxsCounter += 1;
        }
    }

    /**
  * @notice To know if new work is available for worker's address user_
  * @param user_ user
  */
    function IsNewWorkAvailable(address user_) public view returns (bool) {
        bool new_work_available = false;
        WorkerState memory user_state = WorkersState[user_];
        uint256 _currentUserBatch = user_state.allocated_work_batch;
        if (
            !didReveal(user_, _currentUserBatch) &&
            !DataEnded(_currentUserBatch) &&
            !commitPeriodOver(_currentUserBatch)
        ) {
            new_work_available = true;
        }
        return new_work_available;
    }

    /**
  * @notice Get newest work for user
  * @param user_ user
  */
    function GetCurrentWork(address user_) public view returns (uint256) {
        WorkerState memory user_state = WorkersState[user_];
        uint256 _currentUserBatch = user_state.allocated_work_batch;
        // if user has failed to commit and commitPeriod is Over, then currentWork is "missed".
        if (!didCommit(user_, _currentUserBatch) && commitPeriodOver(_currentUserBatch)) {
            _currentUserBatch = 0;
        }

        return _currentUserBatch;
    }

    // ================================================================================
    //                             INPUT DATA FLOW MANAGEMENT
    // ================================================================================

    /**
  * @notice Update the global sliding counter of spotted data, measuring the spots per TIMEFRAME (hour)
  */
    function updateGlobalSpotFlow() public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        uint256 last_timeframe_idx_ = GlobalSpotFlowManager.length - 1;
        uint256 mostRecentTimestamp_ = GlobalSpotFlowManager[last_timeframe_idx_].timestamp;
        if ((block.timestamp - mostRecentTimestamp_) > Parameters.get_SPOT_TIMEFRAME_DURATION()) {
            // cycle & move periods to the left
            for (uint256 i = 0; i < (GlobalSpotFlowManager.length - 1); i++) {
                GlobalSpotFlowManager[i] = GlobalSpotFlowManager[i + 1];
            }
            //update last timeframe with new values & reset counter
            GlobalSpotFlowManager[last_timeframe_idx_].timestamp = block.timestamp;
            GlobalSpotFlowManager[last_timeframe_idx_].counter = 0;
        }
    }

    /**
  * @notice Count the total spots per TIMEFRAME (hour)
  */
    function getGlobalPeriodSpotCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < GlobalSpotFlowManager.length; i++) {
            total += GlobalSpotFlowManager[i].counter;
        }
        return total;
    }


    /**
  * @notice Update the global sliding counter of validated data, measuring the URL per TIMEFRAME (hour)
  */
    function updateItemCount() public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        uint256 last_timeframe_idx_ = ItemFlowManager.length - 1;
        uint256 mostRecentTimestamp_ = ItemFlowManager[last_timeframe_idx_].timestamp;
        if ((block.timestamp - mostRecentTimestamp_) > Parameters.get_SPOT_TIMEFRAME_DURATION()) {
            // cycle & move periods to the left
            for (uint256 i = 0; i < (ItemFlowManager.length - 1); i++) {
                ItemFlowManager[i] = ItemFlowManager[i + 1];
            }
            //update last timeframe with new values & reset counter
            ItemFlowManager[last_timeframe_idx_].timestamp = block.timestamp;
            ItemFlowManager[last_timeframe_idx_].counter = 0;
        }
    }

    /**
  * @notice Count the total spots per TIMEFRAME (hour)
  */
    function getPeriodItemCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < ItemFlowManager.length; i++) {
            total += ItemFlowManager[i].counter;
        }
        return total;
    }

    /**
  * @notice Update the total spots per TIMEFRAME (hour) per USER
  * @param user_ user
  */
    function updateUserSpotFlow(address user_) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        // string[] memory proposedNewFiles = new string[](allocated_workers.length);
        // TimeframeCounter[] storage UserSpotFlowManager = WorkersState[user_].spotflow_manager;
        TimeframeCounter[NB_TIMEFRAMES] storage UserSpotFlowManager = WorkersSpotFlowManager[user_];

        uint256 last_timeframe_idx_ = UserSpotFlowManager.length - 1;
        uint256 mostRecentTimestamp_ = UserSpotFlowManager[last_timeframe_idx_].timestamp;
        if ((block.timestamp - mostRecentTimestamp_) > Parameters.get_SPOT_TIMEFRAME_DURATION()) {
            // cycle & move periods to the left
            for (uint256 i = 0; i < (UserSpotFlowManager.length - 1); i++) {
                UserSpotFlowManager[i] = UserSpotFlowManager[i + 1];
            }
            //update last timeframe with new values & reset counter
            UserSpotFlowManager[last_timeframe_idx_].timestamp = block.timestamp;
            UserSpotFlowManager[last_timeframe_idx_].counter = 0;
        }
    }

    /**
  * @notice Count the total spots per TIMEFRAME (hour) per USER
  * @param user_ user
  */
    function getUserPeriodSpotCount(address user_) public view returns (uint256) {
        TimeframeCounter[NB_TIMEFRAMES] storage UserSpotFlowManager = WorkersSpotFlowManager[user_];
        uint256 total = 0;
        for (uint256 i = 0; i < UserSpotFlowManager.length; i++) {
            total += UserSpotFlowManager[i].counter;
        }
        return total;
    }

    // ================================================================================
    //                             INPUT DATA : SPOTTING
    // ================================================================================

    /**
  * @notice Submit new data to the protocol, in the stream, which will be added to the latest batch
            file_hashs_, URL_domains_ & item_counts_ must be of same length
  * @param file_hashs_ array of IPFS hashes, json format
  * @param URL_domains_ array of URL top domain per file (for statistics purpose)
  * @param item_counts_ array of size (in number of json items)
  * @param extra_ extra information (for indexing / archival purpose)
  */
    function SpotData(
        string[] memory file_hashs_,
        string[] calldata URL_domains_,
        uint256[] memory item_counts_,
        string memory extra_
    ) public returns (uint256 Dataid_) {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        // ---- Spot Flow Management ---------------------------------------
        require(Parameters.get_SPOT_TOGGLE_ENABLED(), "Spotting is not currently enabled by Owner");
        require(file_hashs_.length == URL_domains_.length, "input arrays must be of same length (1)");
        require(file_hashs_.length == item_counts_.length, "input arrays must be of same length (2)");
        // -- global flow checking
        updateGlobalSpotFlow(); // first update the Global SpotFlow Management System
        require(
            getGlobalPeriodSpotCount() < Parameters.get_SPOT_GLOBAL_MAX_SPOT_PER_PERIOD(),
            "Global limit: exceeded max data per hour, retry later."
        );
        //_numTokens The number of tokens to be committed towards the target SpottedData
        uint256 _numTokens = Parameters.get_SPOT_MIN_STAKE();
        address _selectedAddress = SelectAddressForUser(msg.sender, _numTokens);
        // -- woker flow checking
        updateUserSpotFlow(_selectedAddress); // first update the User SpotFlow Management System
        // -----------------------------------------------------------------

        if (
            getUserPeriodSpotCount(_selectedAddress) < Parameters.get_SPOT_MAX_SPOT_PER_USER_PER_PERIOD() &&
            getGlobalPeriodSpotCount() < Parameters.get_SPOT_GLOBAL_MAX_SPOT_PER_PERIOD() &&
            (LastBatchCounter - AllocatedBatchCursor) <= MaxPendingDataBatchCount
        ) {
            if (STAKING_REQUIREMENT_TOGGLE_ENABLED) {
                // ---  Master/SubWorker Stake Management
                // if tx sender has a master, then interact with his master's stake, or himself
                if (SystemStakedTokenBalance[_selectedAddress] < _numTokens) {
                    uint256 remainder = _numTokens - SystemStakedTokenBalance[_selectedAddress];
                    requestAllocatedStake(remainder, _selectedAddress);
                }
            }

            // -----------------------------------------------------------------
            // ---- Spot Batch Processing --------------------------------------
            for (uint256 i = 0; i < file_hashs_.length; i++) {
                string memory file_hash = file_hashs_[i];
                string memory URL_domain_ = URL_domains_[i];
                uint256 item_count_ = item_counts_[i];
                UserSubmissions[msg.sender].push(DataNonce);

                SpotsMapping[DataNonce] = SpottedData({
                    ipfs_hash: file_hash,
                    author: msg.sender,
                    timestamp: block.timestamp,
                    item_count: item_count_,
                    URL_domain: URL_domain_,
                    extra: extra_,
                    status: DataStatus.TBD
                });

                // UPDATE STREAMING DATA BATCH STRUCTURE
                BatchMetadata storage current_data_batch = DataBatch[LastBatchCounter];
                if (current_data_batch.counter < Parameters.get_SPOT_DATA_BATCH_SIZE()) {
                    current_data_batch.counter += 1;
                }
                if (current_data_batch.counter >= Parameters.get_SPOT_DATA_BATCH_SIZE()) {
                    // batch is complete trigger new work round, new batch
                    current_data_batch.complete = true;
                    current_data_batch.checked = false;
                    LastBatchCounter += 1;
                    DataBatch[LastBatchCounter].start_idx = DataNonce;
                }
                // Global state update - spot flow management: increase global sliding counter & user counter
                DataNonce = DataNonce + 1;
                GlobalSpotFlowManager[GlobalSpotFlowManager.length - 1].counter += 1;
                TimeframeCounter[NB_TIMEFRAMES] storage UserSpotFlowManager = WorkersSpotFlowManager[_selectedAddress];
                UserSpotFlowManager[UserSpotFlowManager.length - 1].counter += 1;

                if (InstantSpotRewards) {
                    address spot_author_ = msg.sender;
                    IAddressManager _AddressManager = IAddressManager(Parameters.getAddressManager());
                    IRepManager _RepManager = IRepManager(Parameters.getRepManager());
                    IRewardManager _RewardManager = IRewardManager(Parameters.getRewardManager());
                    address spot_author_master_ = _AddressManager.FetchHighestMaster(spot_author_);
                    uint256 rewardAmount = (Parameters.get_SPOT_MIN_REWARD_SpotData() * 100) /
                        InstantSpotRewardsDivider;
                    uint256 repAmount = (Parameters.get_SPOT_MIN_REP_SpotData() * 100) / InstantSpotRewardsDivider;
                    require(
                        _RepManager.mintReputationForWork(repAmount, spot_author_master_, ""),
                        "could not reward REP in ValidateDataBatch, 2.a"
                    );
                    require(
                        _RewardManager.ProxyAddReward(rewardAmount, spot_author_master_),
                        "could not reward token in ValidateDataBatch, 2.b"
                    );
                }

                // ---- TRIGGER UPDATES ON ALL SYSTEMS ----

                if (TRIGGER_WITH_SPOTDATA_TOGGLE_ENABLED) {
                    TriggerUpdate(1);
                    IFollowingSystem _ComplianceSystem = IFollowingSystem(Parameters.getComplianceSystem());
                    try _ComplianceSystem.TriggerUpdate(1) {} catch (bytes memory err) {
                        emit BytesFailure(err);
                    }
                    IFollowingSystem _IndexingSystem = IFollowingSystem(Parameters.getIndexingSystem());
                    try _IndexingSystem.TriggerUpdate(1) {} catch (bytes memory err) {
                        emit BytesFailure(err);
                    }
                    IFollowingSystem _ArchivingSystem = IFollowingSystem(Parameters.getArchivingSystem());
                    try _ArchivingSystem.TriggerUpdate(1) {} catch (bytes memory err) {
                        emit BytesFailure(err);
                    }
                }
                // ---- Emit event
                emit _SpotSubmitted(DataNonce, file_hash, URL_domain_, _selectedAddress);
            }
            // -----------------------------------------------------------------
        }

        WorkerState storage worker_state = WorkersState[msg.sender];
        
        if ( !IsWorkerSeen[msg.sender] ){
            AllWorkersList.push(msg.sender);
            IsWorkerSeen[msg.sender] = true;
        }

        worker_state.last_interaction_date = block.timestamp;

        _retrieveSFuel();
        AllTxsCounter += 1;
        return DataNonce;
    }

    /**
  * @notice Commits spot-check-vote on a DataBatch
  * @param _DataBatchId DataBatch ID
  * @param _encryptedHash encrypted hash of the submitted IPFS file (json format)
  * @param _encryptedVote encrypted hash of the submitted IPFS vote
  * @param _BatchCount Batch Count in number of items (in the aggregated IPFS hash)
  * @param _From extra information (for indexing / archival purpose)
  */
    function commitSpotCheck(
        uint256 _DataBatchId,
        bytes32 _encryptedHash,
        bytes32 _encryptedVote,
        uint256 _BatchCount,
        string memory _From
    ) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");
        require(commitPeriodActive(_DataBatchId), "commit period needs to be open for this batchId");
        require(!UserChecksCommits[msg.sender][_DataBatchId], "User has already commited to this batchId");
        require(
            isWorkerAllocatedToBatch(_DataBatchId, msg.sender),
            "User needs to be allocated to this batch to commit on it"
        );
        require(Parameters.getAddressManager() != address(0), "AddressManager is null in Parameters");

        // ---  Master/SubWorker Stake Management
        //_numTokens The number of tokens to be committed towards the target SpottedData
        uint256 _numTokens = Parameters.get_SPOT_MIN_STAKE();
        address _selectedAddress = SelectAddressForUser(msg.sender, _numTokens);

        if (STAKING_REQUIREMENT_TOGGLE_ENABLED) {
            // if tx sender has a master, then interact with his master's stake, or himself
            if (SystemStakedTokenBalance[_selectedAddress] < _numTokens) {
                uint256 remainder = _numTokens - SystemStakedTokenBalance[_selectedAddress];
                requestAllocatedStake(remainder, _selectedAddress);
            }
        }

        uint256 _prevDataID = 0;

        // Check if _prevDataID exists in the user's DLL or if _prevDataID is 0
        require(
            _prevDataID == 0 || dllMap[msg.sender].contains(_prevDataID),
            "Error:  _prevDataID exists in the user's DLL or if _prevDataID is 0"
        );

        uint256 nextDataID = dllMap[msg.sender].getNext(_prevDataID);

        // edge case: in-place update
        if (nextDataID == _DataBatchId) {
            nextDataID = dllMap[msg.sender].getNext(_DataBatchId);
        }

        require(validPosition(_prevDataID, nextDataID, msg.sender, _numTokens), "not a valid position");
        dllMap[msg.sender].insert(_prevDataID, _DataBatchId, nextDataID);

        bytes32 UUID = attrUUID(msg.sender, _DataBatchId);

        setAttribute(UUID, "numTokens", _numTokens);
        setAttribute(UUID, "commitHash", uint256(_encryptedHash));
        setAttribute(UUID, "commitVote", uint256(_encryptedVote));

        UserBatchCounts[_DataBatchId][msg.sender] = _BatchCount;
        UserBatchFrom[_DataBatchId][msg.sender] = _From;
        BatchCommitedVoteCount[_DataBatchId] += 1;

        // ----------------------- WORKER STATE UPDATE -----------------------
        WorkerState storage worker_state = WorkersState[msg.sender];
        DataBatch[_DataBatchId].uncommited_workers = DataBatch[_DataBatchId].uncommited_workers - 1;
        worker_state.last_interaction_date = block.timestamp;
        UserChecksCommits[msg.sender][_DataBatchId] = true;

        AllTxsCounter += 1;
        _retrieveSFuel();
        emit _SpotCheckCommitted(_DataBatchId, _numTokens, msg.sender);
    }

    /**
  * @notice Reveals spot-check-vote on a DataBatch
  * @param _DataBatchId DataBatch ID
  * @param _clearIPFSHash clear hash of the submitted IPFS file (json format)
  * @param _clearVote clear hash of the submitted IPFS vote
  * @param _salt arbitraty integer used to hash the previous commit & verify the reveal
  */
    function revealSpotCheck(
        uint256 _DataBatchId,
        string memory _clearIPFSHash,
        uint256 _clearVote,
        uint256 _salt
    ) public {
        // Make sure the reveal period is active
        require(revealPeriodActive(_DataBatchId), "Reveal period not open for this DataID");
        require(UserChecksCommits[msg.sender][_DataBatchId], "User has not commited before, thus can't reveal");
        require(!UserChecksReveals[msg.sender][_DataBatchId], "User has already revealed, thus can't reveal");
        require(
            getEncryptedStringHash(_clearIPFSHash, _salt) == getCommitIPFSHash(msg.sender, _DataBatchId),
            "Not the same hash than commited, impossible to match with given _salt & _clearIPFSHash"
        ); // compare resultant hash from inputs to original commited IPFS hash
        require(
            getEncryptedHash(_clearVote, _salt) == getCommitVoteHash(msg.sender, _DataBatchId),
            "Not the same vote than commited, impossible to match with given _salt & _clearVote"
        ); // compare resultant hash from inputs to original commited vote hash

        if (_clearVote == APPROVAL_VOTE_MAPPING_) {
            // apply numTokens to appropriate SpottedData choice
            DataBatch[_DataBatchId].votesFor += 1;
        } else {
            DataBatch[_DataBatchId].votesAgainst += 1;
        }

        // ----------------------- USER STATE UPDATE -----------------------
        UserChecksReveals[msg.sender][_DataBatchId] = true;
        UserVotes[_DataBatchId][msg.sender] = _clearVote;
        UserNewFiles[_DataBatchId][msg.sender] = _clearIPFSHash;
        BatchRevealedVoteCount[_DataBatchId] += 1;

        // ----------------------- WORKER STATE UPDATE -----------------------
        WorkerState storage worker_state = WorkersState[msg.sender];
        DataBatch[_DataBatchId].unrevealed_workers = DataBatch[_DataBatchId].unrevealed_workers - 1;

        worker_state.last_interaction_date = block.timestamp;

        if (worker_state.registered) {
            // only if the worker is still registered, of course.
            // PUT BACK THE WORKER AS AVAILABLE
            // Mark the current work back to 0, to allow worker to unregister before new work.
            worker_state.allocated_work_batch = 0;
            PopFromBusyWorkers(msg.sender);
            PushInAvailableWorkers(msg.sender);
        }

        if (InstantRevealRewards) {
            address reveal_author_ = msg.sender;
            IAddressManager _AddressManager = IAddressManager(Parameters.getAddressManager());
            IRepManager _RepManager = IRepManager(Parameters.getRepManager());
            IRewardManager _RewardManager = IRewardManager(Parameters.getRewardManager());
            address reveal_author_master_ = _AddressManager.FetchHighestMaster(reveal_author_);
            uint256 repAmount = Parameters.get_SPOT_MIN_REP_DataValidation() *
                                    SPOT_FILE_SIZE/InstantRevealRewardsDivider;
            uint256 rewardAmount = Parameters.get_SPOT_MIN_REWARD_DataValidation() * 
                                    SPOT_FILE_SIZE/InstantRevealRewardsDivider;
            require(
                _RepManager.mintReputationForWork(repAmount, reveal_author_master_, ""),
                "could not reward REP in revealSpotCheck, 1.a"
            );
            require(
                _RewardManager.ProxyAddReward(rewardAmount, reveal_author_master_),
                "could not reward token in revealSpotCheck, 1.b"
            );
        }

        // Move directly to Validation if everyone revealed.
        if (VALIDATE_ON_LAST_REVEAL && DataBatch[_DataBatchId].unrevealed_workers == 0) {
            ValidateDataBatch(_DataBatchId);
        }

        AllTxsCounter += 1;
        _retrieveSFuel();
        emit _SpotCheckRevealed(
            _DataBatchId,
            DataBatch[_DataBatchId].votesFor,
            DataBatch[_DataBatchId].votesAgainst,
            _clearVote,
            msg.sender
        );
    }

    // ================================================================================
    //                              STAKING & TOKEN INTERFACE
    // ================================================================================

    /**
  * @notice Loads _numTokens ERC20 tokens into the voting contract for one-to-one voting rights
  * @dev Assumes that msg.sender has approved voting contract to spend on their behalf
  * @param _numTokens The number of votingTokens desired in exchange for ERC20 tokens
  * @param user_ The user address
  */
    function requestAllocatedStake(uint256 _numTokens, address user_) internal {
        require(Parameters.getStakeManager() != address(0), "StakeManager is null in Parameters");
        IStakeManager _StakeManager = IStakeManager(Parameters.getStakeManager());
        require(
            _StakeManager.ProxyStakeAllocate(_numTokens, user_),
            "Could not request enough allocated stake, requestAllocatedStake"
        );
        SystemStakedTokenBalance[user_] += _numTokens;
        emit _StakeAllocated(_numTokens, user_);
    }

    /**
  * @notice Withdraw _numTokens ERC20 tokens from the voting contract, revoking these voting rights
  * @param _numTokens The number of ERC20 tokens desired in exchange for voting rights
  */
    function withdrawVotingRights(uint256 _numTokens) public {
        require(IParametersManager(address(0)) != Parameters, "Parameters Manager must be set.");        
        address _selectedAddress = SelectAddressForUser(msg.sender, _numTokens);
        uint256 availableTokens = SystemStakedTokenBalance[_selectedAddress] - getLockedTokens(_selectedAddress);
        require(availableTokens >= _numTokens, "availableTokens should be >= _numTokens");

        IStakeManager _StakeManager = IStakeManager(Parameters.getStakeManager());
        SystemStakedTokenBalance[_selectedAddress] -= _numTokens;
        require(
            _StakeManager.ProxyStakeDeallocate(_numTokens, _selectedAddress),
            "Could not withdrawVotingRights through ProxyStakeDeallocate"
        );
        _retrieveSFuel();
        emit _VotingRightsWithdrawn(_numTokens, _selectedAddress);
    }

    /**
  * @notice get Locked Token for the current Contract (WorkSystem)
  * @param user_ The user address
  */
    function getSystemTokenBalance(address user_) public view returns (uint256 tokens) {
        return (uint256(SystemStakedTokenBalance[user_]));
    }

    /**
  * @notice Get Total Accepted Batches
  */
    function getAcceptedBatchesCount() public view returns (uint256 count) {
        return (uint256(AcceptedBatchsCounter));
    }

    /**
  * @notice Get Total Rejected Batches
  */
    function getRejectedBatchesCount() public view returns (uint256 count) {
        return (uint256(RejectedBatchsCounter));
    }

    /**
  * @dev Unlocks tokens locked in unrevealed spot-check-vote where SpottedData has ended
  * @param _DataBatchId Integer identifier associated with the target SpottedData
  */
    function rescueTokens(uint256 _DataBatchId) public {
        require(
            DataBatch[_DataBatchId].status == DataStatus.APPROVED,
            "given DataBatch should be APPROVED, and it is not"
        );
        require(dllMap[msg.sender].contains(_DataBatchId), "dllMap: does not cointain _DataBatchId for the msg sender");

        dllMap[msg.sender].remove(_DataBatchId);
        _retrieveSFuel();
        emit _TokensRescued(_DataBatchId, msg.sender);
    }

    /**
  * @dev Unlocks tokens locked in unrevealed spot-check-votes where Datas have ended
  * @param _DataBatchIDs Array of integer identifiers associated with the target Datas
  */
    function rescueTokensInMultipleDatas(uint256[] memory _DataBatchIDs) public {
        // loop through arrays, rescuing tokens from all
        for (uint256 i = 0; i < _DataBatchIDs.length; i++) {
            rescueTokens(_DataBatchIDs[i]);
        }
    }

    // ================================================================================
    //                              GETTERS - DATA
    // ================================================================================

    /**
  * @notice get all IPFS hashes, input of the batch 
  * @param _DataBatchId ID of the batch
  */
    function getIPFShashesForBatch(uint256 _DataBatchId) public view returns (string[] memory) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");
        BatchMetadata memory batch_ = DataBatch[_DataBatchId];
        uint256 batch_size = batch_.counter;

        string[] memory ipfs_hash_list = new string[](batch_size);

        for (uint256 i = 0; i < batch_size; i++) {
            uint256 k = batch_.start_idx + i;
            string memory ipfs_hash_ = SpotsMapping[k].ipfs_hash;
            ipfs_hash_list[i] = ipfs_hash_;
        }

        return ipfs_hash_list;
    }

    /**
  * @notice get all IPFS hashes, input of batchs, between batch indices A and B (a < B)
  * @param _DataBatchId_a ID of the starting batch
  * @param _DataBatchId_b ID of the ending batch (included)
  */
    function getMultiBatchIPFShashes(uint256 _DataBatchId_a, uint256 _DataBatchId_b)
        public
        view
        returns (string[] memory)
    {
        require(_DataBatchId_a > 0 && _DataBatchId_a < _DataBatchId_b, "Input boundaries are invalid");
        uint256 _ipfs_hash_count = 0;

        for (uint256 batchI = _DataBatchId_a; batchI < _DataBatchId_b + 1; batchI++) {
            BatchMetadata memory batch_ = DataBatch[batchI];
            _ipfs_hash_count += batch_.counter;
        }
        string[] memory ipfs_hash_list = new string[](_ipfs_hash_count);

        uint256 c = 0;
        for (uint256 batchI = _DataBatchId_a; batchI < _DataBatchId_b + 1; batchI++) {
            BatchMetadata memory batch_ = DataBatch[batchI];
            for (uint256 i = 0; i < batch_.counter; i++) {
                uint256 k = batch_.start_idx + i;
                string memory ipfs_hash_ = SpotsMapping[k].ipfs_hash;
                ipfs_hash_list[c] = ipfs_hash_;
                c += 1;
            }
        }

        return ipfs_hash_list;
    }


    /**
  * @notice get all item counts for all batches between batch indices A and B (a < B)
  * @param _DataBatchId_a ID of the starting batch
  * @param _DataBatchId_b ID of the ending batch (included)
  */
    function getBatchCountForBatch(uint256 _DataBatchId_a, uint256 _DataBatchId_b)
        public
        view
        returns (uint256 AverageURLCount, uint256[] memory batchCounts)
    {
        require(_DataBatchId_a > 0 && _DataBatchId_a < _DataBatchId_b, "Input boundaries are invalid");
        uint256 _total_batchs_count = 0;
        uint256 _batch_amount = _DataBatchId_b - _DataBatchId_a + 1;

        uint256[] memory _batch_counts_list = new uint256[](_batch_amount);

        for (uint256 i=0; i < _batch_amount ; i++) {
            BatchMetadata memory batch_ = DataBatch[i+_DataBatchId_a];
            _total_batchs_count += batch_.item_count;
            _batch_counts_list[i] = batch_.item_count;
        }

        uint256 _average_batch_count = _total_batchs_count / _batch_amount;

        return (_average_batch_count, _batch_counts_list);
    }

    /**
  * @notice get top domain URL for a given batch
  * @param _DataBatchId ID of the batch
  */
    function getDomainsForBatch(uint256 _DataBatchId) public view returns (string[] memory) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");
        BatchMetadata memory batch_ = DataBatch[_DataBatchId];
        uint256 batch_size = batch_.counter;

        string[] memory ipfs_hash_list = new string[](batch_size);

        for (uint256 i = 0; i < batch_size; i++) {
            uint256 k = batch_.start_idx + i;
            string memory ipfs_hash_ = SpotsMapping[k].URL_domain;
            ipfs_hash_list[i] = ipfs_hash_;
        }

        return ipfs_hash_list;
    }

    /**
  * @notice get the From information for a given batch
  * @param _DataBatchId ID of the batch
  */
    function getFromsForBatch(uint256 _DataBatchId) public view returns (string[] memory) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
        string[] memory from_list = new string[](allocated_workers.length);

        for (uint256 i = 0; i < allocated_workers.length; i++) {
            from_list[i] = UserBatchFrom[_DataBatchId][allocated_workers[i]];
        }
        return from_list;
    }

    /**
  * @notice get all Votes on a given batch
  * @param _DataBatchId ID of the batch
  */
    function getVotesForBatch(uint256 _DataBatchId) public view returns (uint256[] memory) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
        uint256[] memory votes_list = new uint256[](allocated_workers.length);

        for (uint256 i = 0; i < allocated_workers.length; i++) {
            votes_list[i] = UserVotes[_DataBatchId][allocated_workers[i]];
        }
        return votes_list;
    }

    /**
  * @notice get all IPFS files submitted (during commit/reveal) on a given batch
  * @param _DataBatchId ID of the batch
  */
    function getSubmittedFilesForBatch(uint256 _DataBatchId) public view returns (string[] memory) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
        string[] memory files_list = new string[](allocated_workers.length);

        for (uint256 i = 0; i < allocated_workers.length; i++) {
            files_list[i] = UserNewFiles[_DataBatchId][allocated_workers[i]];
        }
        return files_list;
    }

    /**
  * @notice Get all current workers
  */
    function getActiveWorkersCount() public view returns (uint256 numWorkers) {
        return (uint256(availableWorkers.length + busyWorkers.length));
    }

    /**
  * @notice Get all available (idle) workers
  */
    function getAvailableWorkersCount() public view returns (uint256 numWorkers) {
        return (uint256(availableWorkers.length));
    }

    /**
  * @notice Get all busy workers
  */
    function getBusyWorkersCount() public view returns (uint256 numWorkers) {
        return (uint256(busyWorkers.length));
    }


    // ----------------------------------------------------
    // ----------------------------------------------------
    //                     Data HELPERS
    // ----------------------------------------------------
    // ----------------------------------------------------

    /**
  * @dev Compares previous and next SpottedData's committed tokens for sorting purposes
  * @param _prevID Integer identifier associated with previous SpottedData in sorted order
  * @param _nextID Integer identifier associated with next SpottedData in sorted order
  * @param _voter Address of user to check DLL position for
  * @param _numTokens The number of tokens to be committed towards the SpottedData (used for sorting)
  * @return APPROVED Boolean indication of if the specified position maintains the sort
  */
    function validPosition(
        uint256 _prevID,
        uint256 _nextID,
        address _voter,
        uint256 _numTokens
    ) public view returns (bool APPROVED) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
        // if next is zero node, _numTokens does not need to be greater
        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
        return prevValid && nextValid;
    }

    /**
  * @notice Determines if proposal has passed
  * @dev Check if votesFor out of totalSpotChecks exceeds votesQuorum (requires DataEnded)
  * @param _DataBatchId Integer identifier associated with target SpottedData
  */
    function isPassed(uint256 _DataBatchId) public view returns (bool passed) {
        BatchMetadata memory batch_ = DataBatch[_DataBatchId];
        return (100 * batch_.votesFor) > (Parameters.getVoteQuorum() * (batch_.votesFor + batch_.votesAgainst));
    }

    /**
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @param _salt Arbitrarily chosen integer used to generate secretHash
  * @return correctSpotChecks Number of tokens voted for winning option
  */
    function getNumPassingTokens(
        address _voter,
        uint256 _DataBatchId,
        uint256 _salt
    ) public view returns (uint256 correctSpotChecks) {
        require(DataEnded(_DataBatchId), "_DataBatchId checking vote must have ended");
        require(UserChecksReveals[_voter][_DataBatchId], "user must have revealed in this given Batch");

        uint256 winningChoice = isPassed(_DataBatchId) ? 1 : 0;
        bytes32 winnerHash = keccak256(abi.encodePacked(winningChoice, _salt));
        bytes32 commitHash = getCommitVoteHash(_voter, _DataBatchId);

        require(winnerHash == commitHash, "getNumPassingTokens: hashes must be equal");

        return getNumTokens(_voter, _DataBatchId);
    }

    /**
  * @notice Determines if SpottedData is over
  * @dev Checks isExpired for specified SpottedData's revealEndDate
  * @return ended Boolean indication of whether Dataing period is over
  */
    function DataEnded(uint256 _DataBatchId) public view returns (bool ended) {
        require(DataExists(_DataBatchId), "Data must exist");

        return isExpired(DataBatch[_DataBatchId].revealEndDate)
                || (commitPeriodOver(_DataBatchId) && BatchCommitedVoteCount[_DataBatchId] == 0);
    }

    /**
  * @notice Get User Submitted Data (Spots)
  * @return user_Datas the array of Data Spotted/Submitted by the user
  */
    function getUserDatas(address user) public view returns (uint256[] memory user_Datas) {
        return UserSubmissions[user];
    }

    /**
  * @notice get Last Data Id
  * @return DataId
  */
    function getLastDataId() public view returns (uint256 DataId) {
        return DataNonce;
    }

    /**
  * @notice get Last Batch Id
  * @return LastBatchId
  */
    function getLastBatchId() public view returns (uint256 LastBatchId) {
        return LastBatchCounter;
    }

    /**
  * @notice get Last Checked Batch Id
  * @return LastCheckedBatchId
  */
    function getLastCheckedBatchId() public view returns (uint256 LastCheckedBatchId) {
        return BatchCheckingCursor;
    }

    /**
  * @notice getLastAllocatedBatchId
  * @return LastAllocatedBatchId
  */
    function getLastAllocatedBatchId() public view returns (uint256 LastAllocatedBatchId) {
        return AllocatedBatchCursor;
    }

    /**
  * @notice get DataBatch By ID
  * @return batch as BatchMetadata struct
  */
    function getBatchByID(uint256 _DataBatchId) public view returns (BatchMetadata memory batch) {
        require(DataExists(_DataBatchId));
        return DataBatch[_DataBatchId];
    }

    /**
  * @notice get Output Batch IPFS File By ID
  * @return batch IPFS File
  */
    function getBatchIPFSFileByID(uint256 _DataBatchId) public view returns (string memory batch) {
        require(DataExists(_DataBatchId));
        return DataBatch[_DataBatchId].batchIPFSfile;
    }
    
    /**
  * @notice get all Output Batch IPFS Files (hashes),between batch indices A and B (a < B)
  * @param _DataBatchId_a ID of the starting batch
  * @param _DataBatchId_b ID of the ending batch (included)
  * @return array of Batch File ID between index A and B included
  */
  
    function getBatchsFilesByID(uint256 _DataBatchId_a, uint256 _DataBatchId_b)
        public
        view
        returns (string[] memory)
    {
        require(_DataBatchId_a > 0 && _DataBatchId_a < _DataBatchId_b, "Input boundaries are invalid");
        uint256 _array_size = _DataBatchId_b - _DataBatchId_a+1;
        string[] memory ipfs_hash_list = new string[](_array_size);
        for (uint256 i = 0; i < _array_size; i++) {
            ipfs_hash_list[i] = DataBatch[i+_DataBatchId_a].batchIPFSfile;
        }
        return ipfs_hash_list;
    }

    
    /**
  * @dev Returns all worker addresses between index A_ and index B
  * @param A_ Address of user to check against
  * @param B_ Integer identifier associated with target SpottedData
  * @return workers array of workers of size (B_-A_+1)
  */
    function getAllWorkersBetweenIndex(uint256 A_, uint256 B_) public view returns (address[] memory workers) {
        require(B_>= A_, " _B must be >= _A");
        require(B_<= (AllWorkersList.length -1), " B_ is out of bounds");
        uint256 _array_size = B_ - A_+1;
        address[] memory address_list = new address[](_array_size);
        for (uint256 i = 0; i < _array_size; i++) {
            address_list[i] = AllWorkersList[i+A_];
        }
        return address_list;
    }

    /**
  * @notice get AllWorkersList length
  * @return length of the array
  */
    function getAllWorkersLength() public view returns (uint256 length) {
        return AllWorkersList.length;
    }

    /**
  * @notice get Data By ID
  * @return data as SpottedData struct
  */
    function getDataByID(uint256 _DataId) public view returns (SpottedData memory data) {
        return SpotsMapping[_DataId];
    }

    /**
  * @notice getCounter
  * @return Counter of all "accepted transactions"
  */
    function getTxCounter() public view returns (uint256 Counter) {
        return AllTxsCounter;
    }

    /**
  * @notice getCounter
  * @return Counter of the last Dataed a user started
  */
    function getItemCounter() public view returns (uint256 Counter) {
        return AllItemCounter;
    }

    /**
  * @notice Determines DataCommitEndDate
  * @return commitEndDate indication of whether Dataing period is over
  */
    function DataCommitEndDate(uint256 _DataBatchId) public view returns (uint256 commitEndDate) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        return DataBatch[_DataBatchId].commitEndDate;
    }

    /**
  * @notice Determines DataRevealEndDate
  * @return revealEndDate indication of whether Dataing period is over
  */
    function DataRevealEndDate(uint256 _DataBatchId) public view returns (uint256 revealEndDate) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        return DataBatch[_DataBatchId].revealEndDate;
    }

    /**
  * @notice Checks if the commit period is still active for the specified SpottedData
  * @dev Checks isExpired for the specified SpottedData's commitEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return active Boolean indication of isCommitPeriodActive for target SpottedData
  */
    function commitPeriodActive(uint256 _DataBatchId) public view returns (bool active) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        return !isExpired(DataBatch[_DataBatchId].commitEndDate) && (DataBatch[_DataBatchId].uncommited_workers > 0);
    }

    /**
  * @notice Checks if the commit period is over
  * @dev Checks isExpired for the specified SpottedData's commitEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return active Boolean indication of isCommitPeriodActive for target SpottedData
  */
    function commitPeriodOver(uint256 _DataBatchId) public view returns (bool active) {
        if (!DataExists(_DataBatchId)) {
            return false;
        } else {
            // a commitPeriod is Over if : time has expired OR if revealPeriod for the same _DataBatchId is true
            return isExpired(DataBatch[_DataBatchId].commitEndDate) || revealPeriodActive(_DataBatchId);
        }
    }

    /**
  * @notice Checks if the commit period is still active for the specified SpottedData
  * @dev Checks isExpired for the specified SpottedData's commitEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return remainingTime Integer
  */
    function remainingCommitDuration(uint256 _DataBatchId) public view returns (uint256 remainingTime) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");
        uint256 _remainingTime = 0;
        if (commitPeriodActive(_DataBatchId)) {
            _remainingTime = DataBatch[_DataBatchId].commitEndDate - block.timestamp;
        }
        return _remainingTime;
    }

    /**
  * @notice Checks if the reveal period is still active for the specified SpottedData
  * @dev Checks isExpired for the specified SpottedData's revealEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  */
    function revealPeriodActive(uint256 _DataBatchId) public view returns (bool active) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        return !isExpired(DataBatch[_DataBatchId].revealEndDate) && !commitPeriodActive(_DataBatchId);
    }

    /**
  * @notice Checks if the reveal period is over
  * @dev Checks isExpired for the specified SpottedData's revealEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  */
    function revealPeriodOver(uint256 _DataBatchId) public view returns (bool active) {
        if (!DataExists(_DataBatchId)) {
            return false;
        } else {
            // a commitPeriod is Over if : time has expired OR if revealPeriod for the same _DataBatchId is true
            return isExpired(DataBatch[_DataBatchId].revealEndDate) || DataBatch[_DataBatchId].unrevealed_workers == 0;
        }
    }

    /**
  * @notice Checks if the commit period is still active for the specified SpottedData
  * @dev Checks isExpired for the specified SpottedData's commitEndDate
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return remainingTime Integer indication of isCommitPeriodActive for target SpottedData
  */
    function remainingRevealDuration(uint256 _DataBatchId) public view returns (uint256 remainingTime) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");
        uint256 _remainingTime = 0;
        if (revealPeriodActive(_DataBatchId)) {
            _remainingTime = DataBatch[_DataBatchId].revealEndDate - block.timestamp;
        }
        return _remainingTime;
    }

    /**
  * @dev Checks if user has committed for specified SpottedData
  * @param _voter Address of user to check against
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return committed Boolean indication of whether user has committed
  */
    function didCommit(address _voter, uint256 _DataBatchId) public view returns (bool committed) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        // return SpotsMapping[_DataBatchId].didCommit[_voter];
        return UserChecksCommits[_voter][_DataBatchId];
    }

    /**
  * @dev Checks if user has revealed for specified SpottedData
  * @param _voter Address of user to check against
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return revealed Boolean indication of whether user has revealed
  */
    function didReveal(address _voter, uint256 _DataBatchId) public view returns (bool revealed) {
        require(DataExists(_DataBatchId), "_DataBatchId must exist");

        // return SpotsMapping[_DataBatchId].didReveal[_voter];
        return UserChecksReveals[_voter][_DataBatchId];
    }

    

    /**
  * @dev Checks if a SpottedData exists
  * @param _DataBatchId The DataID whose existance is to be evaluated.
  * @return exists Boolean Indicates whether a SpottedData exists for the provided DataID
  */
    function DataExists(uint256 _DataBatchId) public view returns (bool exists) {
        return (DataBatch[_DataBatchId].complete);
    }

    function AmIRegistered() public view returns (bool passed) {
        return WorkersState[msg.sender].registered;
    }

    function isWorkerRegistered(address _worker) public view returns (bool passed) {
        return WorkersState[_worker].registered;
    }

    // ------------------------------------------------------------------------------------------------------------
    // DOUBLE-LINKED-LIST HELPERS:
    // ------------------------------------------------------------------------------------------------------------

    /**
  * @dev Gets the bytes32 commitHash property of target SpottedData
  * @param _voter Address of user to check against
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return commitHash Bytes32 hash property attached to target SpottedData
  */
    function getCommitVoteHash(address _voter, uint256 _DataBatchId) public view returns (bytes32 commitHash) {
        return bytes32(getAttribute(attrUUID(_voter, _DataBatchId), "commitVote"));
    }

    /**
  * @dev Gets the bytes32 commitHash property of target SpottedData
  * @param _voter Address of user to check against
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return commitHash Bytes32 hash property attached to target SpottedData
  */
    function getCommitIPFSHash(address _voter, uint256 _DataBatchId) public view returns (bytes32 commitHash) {
        return bytes32(getAttribute(attrUUID(_voter, _DataBatchId), "commitHash"));
    }

    /**
  * @dev Gets the bytes32 commitHash property of target SpottedData
  * @param _clearVote vote Option
  * @param _salt is the salt
  * @return keccak256hash Bytes32 hash property attached to target SpottedData
  */
    function getEncryptedHash(uint256 _clearVote, uint256 _salt) public pure returns (bytes32 keccak256hash) {
        return keccak256(abi.encodePacked(_clearVote, _salt));
    }

    /**
  * @dev Gets the bytes32 commitHash property of target FormattedData
  * @param _hash ipfs hash of aggregated data in a string
  * @param _salt is the salt
  * @return keccak256hash Bytes32 hash property attached to target FormattedData
  */
    function getEncryptedStringHash(string memory _hash, uint256 _salt) public pure returns (bytes32 keccak256hash) {
        return keccak256(abi.encode(_hash, _salt));
    }

    /**
  * @dev Wrapper for getAttribute with attrName="numTokens"
  * @param _voter Address of user to check against
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return numTokens Number of tokens committed to SpottedData in sorted SpottedData-linked-list
  */
    function getNumTokens(address _voter, uint256 _DataBatchId) public view returns (uint256 numTokens) {
        return getAttribute(attrUUID(_voter, _DataBatchId), "numTokens");
    }

    /**
  * @dev Gets top element of sorted SpottedData-linked-list
  * @param _voter Address of user to check against
  * @return DataID Integer identifier to SpottedData with maximum number of tokens committed to it
  */
    function getLastNode(address _voter) public view returns (uint256 DataID) {
        return dllMap[_voter].getPrev(0);
    }

    /**
  * @dev Gets the numTokens property of getLastNode
  * @param _voter Address of user to check against
  * @return numTokens Maximum number of tokens committed in SpottedData specified
  */
    function getLockedTokens(address _voter) public view returns (uint256 numTokens) {
        return getNumTokens(_voter, getLastNode(_voter));
    }

    /*
  * @dev Takes the last node in the user's DLL and iterates backwards through the list searching
  for a node with a value less than or equal to the provided _numTokens value. When such a node
  is found, if the provided _DataBatchId matches the found nodeID, this operation is an in-place
  update. In that case, return the previous node of the node being updated. Otherwise return the
  first node that was found with a value less than or equal to the provided _numTokens.
  * @param _voter The voter whose DLL will be searched
  * @param _numTokens The value for the numTokens attribute in the node to be inserted
  * @return the node which the propoded node should be inserted after
  */
    function getInsertPointForNumTokens(
        address _voter,
        uint256 _numTokens,
        uint256 _DataBatchId
    ) public view returns (uint256 prevNode) {
        // Get the last node in the list and the number of tokens in that node
        uint256 nodeID = getLastNode(_voter);
        uint256 tokensInNode = getNumTokens(_voter, nodeID);

        // Iterate backwards through the list until reaching the root node
        while (nodeID != 0) {
            // Get the number of tokens in the current node
            tokensInNode = getNumTokens(_voter, nodeID);
            if (tokensInNode <= _numTokens) {
                // We found the insert point!
                if (nodeID == _DataBatchId) {
                    // This is an in-place update. Return the prev node of the node being updated
                    nodeID = dllMap[_voter].getPrev(nodeID);
                }
                // Return the insert point
                return nodeID;
            }
            // We did not find the insert point. Continue iterating backwards through the list
            nodeID = dllMap[_voter].getPrev(nodeID);
        }

        // The list is empty, or a smaller value than anything else in the list is being inserted
        return nodeID;
    }

    // ----------------
    // GENERAL HELPERS:
    // ----------------

    /**
  * @dev Checks if an expiration date has been reached
  * @param _terminationDate Integer timestamp of date to compare current timestamp with
  * @return expired Boolean indication of whether the terminationDate has passed
  */
    function isExpired(uint256 _terminationDate) public view returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }

    /**
  * @dev Generates an identifier which associates a user and a SpottedData together
  * @param _DataBatchId Integer identifier associated with target SpottedData
  * @return UUID Hash which is deterministic from user_ and _DataBatchId
  */
    function attrUUID(address user_, uint256 _DataBatchId) public pure returns (bytes32 UUID) {
        return keccak256(abi.encodePacked(user_, _DataBatchId));
    }
}
