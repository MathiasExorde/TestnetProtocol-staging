// SPDX-License-Identifier: GPL-3.0
// File: attrstore/AttributeStore.sol

pragma solidity 0.8.0;

interface IStakeManager {
    function ProxyStakeAllocate(uint256 _StakeAllocation, address _stakeholder) external returns(bool);
    function ProxyStakeDeallocate(uint256 _StakeToDeallocate, address _stakeholder) external returns(bool);
}

interface IRepManager {
    function mintReputationForWork(uint256 _amount, address _beneficiary, bytes32) external returns (bool);    
    function burnReputationForWork(uint256 _amount, address _beneficiary, bytes32) external returns (bool);
}

interface IRewardManager {
    function ProxyAddReward(uint256 _RewardsAllocation, address _user) external returns(bool);
}

interface IAddressManager {
    function isSenderMasterOf(address _address) external returns (bool);
    function isSenderSubOf(address _master) external returns (bool);
    function isSubAddress(address _master, address _address) external returns (bool);
    function addAddress(address _address) external;
    function removeAddress(address _address) external;        
}

interface IFormattingSystem {

    enum DataStatus{
        TBD,
        APPROVED,
        REJECTED,
        FLAGGED
    }

    // ------ Data batch Structure
    struct BatchMetadata {
        uint256 start_idx;
        uint256 counter;
        uint256 uncommited_workers;
        uint256 unrevealed_workers;
        uint256 item_count;
        bool complete;
        bool checked;
        bool allocated_to_work;
        uint256 commitEndDate;                     // expiration date of commit period for poll
        uint256 revealEndDate;                     // expiration date of reveal period for poll
        uint256 votesFor;		                    // tally of format-check-votes supporting proposal
        uint256 votesAgainst;                      // tally of format-check-votes countering proposal
        string batchIPFSfile;                       // to be updated during FormatChecking
        DataStatus status;                 // state of the vote
    }

    // ------ Atomic Data Structure
    struct FormattedData {
        string ipfs_hash;                      // expiration date of commit period for FormattedData
        address author;                         // author of the proposal
        uint256 timestamp;                      // expiration date of commit period for FormattedData
        DataStatus status;                 // state of the vote
    }

    function getIPFShashesForBatch(uint256 _DataBatchId) external returns (string[] memory);

    function getDomainsForBatch(uint256 _DataBatchId) external returns (string[] memory);

    function getLastBatchId() external returns (uint256 LastBatchId);
    
    function getLastCheckedBatchId() external returns (uint256 LastCheckedBatchId);
    
    function getBatchByID(uint256 _DataBatchId) external returns (BatchMetadata memory batch);
    
    function DataExists(uint256 _DataBatchId) external returns  (bool exists);
    
}



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomAllocator.sol";

/**
@title WorkSystem Archive v0.2
@author Mathias Dail
*/
contract DataArchive is Ownable, RandomAllocator {

    // ============
    // EVENTS:
    // ============

    event _DataArchive(uint256 indexed DataID, string file_hash, address  sender);
    
    event _WorkAllocated(uint256 indexed batchID, address worker);
    event _WorkerRegistered(address indexed worker, uint256 timestamp);
    event _WorkerUnregistered(address indexed worker, uint256 timestamp);

    event _VotingRightsGranted(uint256 numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint256 numTokens, address indexed voter);
    event _TokensRescued(uint256 indexed DataID, address indexed voter);

    // ============
    // FormattedData STRUCTURES:
    // ============

    // using AttributeStore2 for AttributeStore2.FormattedData;
    // using DLL2 for DLL2.FormattedData;
    using SafeMath for uint256;
    
    enum DataStatus{
        TBD,
        APPROVED,
        REJECTED,
        FLAGGED
    }

    // struct WorkerState {
    //     address worker_address;                 // worker address
    //     address master_address;                 // main/master worker Address
    //     uint256 allocated_work_batch;
    //     bool has_completed_work;
    //     uint256 last_worked_round;              
    //     uint256 last_interaction_date;       
    //     string extra;                          // extra_data
    //     bool registered;
    //     uint256 registration_date;       
    // }
    
    // struct BatchMetadata {
    //     uint256 start_idx;
    //     uint256 end_idx;
    //     uint256 counter;
    //     uint256 unrevealed_workers;
    //     bool complete;
    //     bool checked;
    //     bool allocated_to_work;
    //     uint256 commitEndDate;                     // expiration date of commit period for poll
    //     uint256 revealEndDate;                     // expiration date of reveal period for poll
    //     uint256 votesFor;		                    // tally of Archive-check-votes supporting proposal
    //     uint256 votesAgainst;                      // tally of Archive-check-votes countering proposal
    //     string batchIPFSfile;                       // to be updated during ArchiveChecking
    //     DataStatus status;                 // state of the vote
    //     string[] flags;                         // string tags
    //     uint256[] flags_id;                     // id of tags
    // }

    struct ArchiveData {
        string ipfs_hash;                      // expiration date of commit period for FormattedData
        address author;                         // author of the proposal
        uint256 timestamp;                      // expiration date of commit period for FormattedData
        DataStatus status;                 // state of the vote
        // string URL_domain;                      // URL domain
        // string[] tags;                          // string tags
        // uint256[] tags_id;                      // id of tags
        // string extra;                          // extra_data
    }

    // ============
    // STATE VARIABLES:
    // ============

    uint256 constant INITIAL_Data_NONCE = 0;
    // uint256 constant INITIAL_Checks_NONCE = 0;
    // uint256 constant MAX_TOTAL_WORKERS = 1000;
    // uint256 public DATA_BATCH_SIZE = 1;
    // uint256 public MIN_STAKE;
    // uint256 public COMMIT_ROUND_DURATION;
    // uint256 public REVEAL_ROUND_DURATION;        
    // uint256 public MIN_REWARD_Data = 1 * (10 ** 18);
    // uint256 public MIN_REP_REVEAL = 1 * (10 ** 18);
    // uint256 public MIN_REP_Data  = 2 * (10 ** 18);
    // uint256 public SPOT_CHECK_VOTE_QUORUM  = 60;
    // uint256 public CONSENSUS_WORKER_SIZE  = 5;
    

    // mapping(address => mapping(uint256 => bool)) public UserChecksCommits;     // indicates whether an address committed a Archive-check-vote for this poll
    // mapping(address => mapping(uint256 => bool)) public UserChecksReveals;     // indicates whether an address revealed a Archive-check-vote for this poll
    // mapping(uint256 => mapping(address => uint256)) public UserVotes;     // maps DataID -> user addresses ->  vote option
    // mapping(uint256 => mapping(address => string)) public UserNewFiles;     // maps DataID -> user addresses -> ipfs string -> counter

    mapping(uint256 => bool) public CollectedFormatBatchs; // maps DataID to FormattedData struct
    
    // mapping(address => DLL2.FormattedData) dllMap;
    // AttributeStore2.FormattedData store;
    
    uint256 public DataNonce = 0;
    

    // mapping(address => WorkerState) public WorkersState;
    mapping(uint256 => ArchiveData) public ArchiveMapping; // maps DataID to FormattedData struct
    mapping(address => uint256) public FormatStakedTokenBalance; // maps user's address to voteToken balance


    mapping(address => address[]) public MasterWorkers;
    address[] public availableWorkers;
    address[] public busyWorkers;   
    mapping(uint256 => address[]) public WorkersPerBatch;

    address public sFuel = 0x14F52f3FC010ab6cA81568D4A6794D5eAB3c6155; //whispering turais testnet, sFuel top up contract
    // owner of sFuelDistributor / Faucet needs to whitelist this contract


    uint256 public LastBatchCounter = 1;
    uint256 public BatchCheckingCursor = 1;
    uint256 public AllocatedBatchCursor = 1;
    // mapping(uint256 => BatchMetadata) public DataBatch; // refers to FormattedData indices
    
    
    uint256 public AllTxsCounter = 0;


    IERC20 public token;
    IStakeManager public StakeManager;
    IRepManager public RepManager;
    IRewardManager public RewardManager;
    IAddressManager public AddressManager;

    IFormattingSystem public FormattingSystem;


    /**
    @dev Initializer. Can only be called once.
    */
    constructor(address EXDT_token, address _FormattingSystem)  {        
        token = IERC20(EXDT_token);
        FormattingSystem = IFormattingSystem(_FormattingSystem);

        DataNonce = INITIAL_Data_NONCE;
        
        // MIN_STAKE = 25 * (10 ** 18); // 100 EXDT to participate
        // COMMIT_ROUND_DURATION = 180;
        // REVEAL_ROUND_DURATION = 180;
    }
    

    function updateStakeManager(address addr)
    public
    onlyOwner
    {
        StakeManager = IStakeManager(addr);
    }
    
    function updateRepManager(address addr)
    public
    onlyOwner
    {
        RepManager  = IRepManager(addr);
    }
    
    function updateRewardManager(address addr)
    public
    onlyOwner
    {
        RewardManager  = IRewardManager(addr);
    }

    function updatePreviousSystem(address addr)
    public
    onlyOwner
    {
        FormattingSystem = IFormattingSystem(addr);
    }

    function updateAddressManager(address addr)
    public
    onlyOwner
    {
        AddressManager  = IAddressManager(addr);
    }

    // function updateDataBachSize(uint256 size)
    // public
    // onlyOwner
    // {
    //     DATA_BATCH_SIZE  = size;
    // }
    
    // function updateCommitRoundDuration(uint256 COMMIT_ROUND_DURATION_)
    // public
    // onlyOwner
    // {
    //     COMMIT_ROUND_DURATION  = COMMIT_ROUND_DURATION_;
    // }
    
    // function updateRevealRoundDuration(uint256 REVEAL_ROUND_DURATION_)
    // public
    // onlyOwner
    // {
    //     REVEAL_ROUND_DURATION  = REVEAL_ROUND_DURATION_;
    // }

    // function updateConsensusSize(uint256 CONSENSUS_WORKER_SIZE_)
    // public
    // onlyOwner
    // {
    //     CONSENSUS_WORKER_SIZE  = CONSENSUS_WORKER_SIZE_;
    // }
    // --------------- SFUEL MANAGEMENT SYSTEM ---------------
    // ---------------


    // function updatesFuelFaucet(address sFuel_)
    // public
    // onlyOwner
    // {
    //     sFuel  = sFuel_;
    // }

    function _retrieveSFuel() internal {
        require(sFuel != address(0), "0 Address Not Valid");
		(bool success1, /* bytes memory data1 */) = sFuel.call(abi.encodeWithSignature("retrieveSFuel(address)", payable(msg.sender)));
        (bool success2, /* bytes memory data2 */) = sFuel.call(abi.encodeWithSignature("retrieveSFuel(address payable)", payable(msg.sender)));
        require(( success1 || success2 ), "receiver rejected _retrieveSFuel call");

    }

    modifier topUpSFuel {
            _retrieveSFuel();
            _;
    }
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    //                          WORKER REGISTRATION & LOBBY MANAGEMENT
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    

    function isInAvailableWorkers(address _worker) internal view returns(bool){
        bool found = false;
        for(uint256 i = 0; i< availableWorkers.length; i++){
            if(availableWorkers[i] == _worker){
                found = true;
                break;
            }
        }
        return found;
    }

    function isInBusyWorkers(address _worker) internal view returns(bool){
        bool found = false;
        for(uint256 i = 0; i< busyWorkers.length; i++){
            if(busyWorkers[i] == _worker){
                found = true;
                break;
            }
        }
        return found;
    }




    function PopFromAvailableWorkers(address _worker) internal{
        uint256 index = 0;
        bool found = false;
        for(uint256 i = 0; i< availableWorkers.length; i++){
            if(availableWorkers[i] == _worker){
                found = true;
                index = i;
                break;
            }
        }
        // require(found, "not found when PopFromAvailableWorkers");
        if(found){
            availableWorkers[index] = availableWorkers[availableWorkers.length - 1];
            availableWorkers.pop();
        }
    }


    function PopFromBusyWorkers(address _worker) internal{
        uint256 index = 0;
        bool found = false;
        for(uint256 i = 0; i< busyWorkers.length; i++){
            if(busyWorkers[i] == _worker){
                found = true;
                index = i;
                break;
            }
        }
        // require(found, "not found when PopFromBusyWorkers");
        if(found){
            busyWorkers[index] = busyWorkers[busyWorkers.length - 1];
            busyWorkers.pop();
        }
    }


    // /////////////////////////////////////////////////////////////////////
    // /* Register worker (online) */
    // function RegisterWorker() public topUpSFuel {
    //     WorkerState storage worker_state = WorkersState[msg.sender];
    //     require((availableWorkers.length+busyWorkers.length) < MAX_TOTAL_WORKERS, "Maximum registered workers already");
    //     require(worker_state.registered == false, "Worker is already registered");
    //     uint256 now_ = getBlockTimestamp();

    //     //_numTokens The number of tokens to be committed towards the target FormattedData
    //     uint256 _numTokens = MIN_STAKE;
        
    //     // if msg.sender doesn't have enough voting rights,
    //     // request for enough voting rights
    //     if (FormatStakedTokenBalance[msg.sender] < _numTokens) {
    //         uint256 remainder = _numTokens.sub(FormatStakedTokenBalance[msg.sender]);
    //         requestVotingRights(remainder);
    //     }

    //     // make sure msg.sender has enough voting rights
    //     require(FormatStakedTokenBalance[msg.sender] >= _numTokens, "Worker has not enough (_numTokens) in his FormatStakedTokenBalance ");
    //     //////////////////////////////////
    //     if(!isInAvailableWorkers(msg.sender)){
    //         availableWorkers.push(msg.sender);
    //     }
    //     // busyWorkers;
    //     worker_state.worker_address = msg.sender;
    //     worker_state.master_address = msg.sender;
    //     worker_state.last_interaction_date = now_;
    //     if(worker_state.registered == false){
    //         worker_state.registered = true;
    //         worker_state.registration_date = block.timestamp;
    //     }

    //     AllTxsCounter += 1;
    //     emit _WorkerRegistered(msg.sender, now_);
    // }

    // /////////////////////////////////////////////////////////////////////
    // /* Unregister worker (offline) */
    // function UnregisterWorker() public topUpSFuel {
    //     WorkerState storage worker_state = WorkersState[msg.sender];
    //     require(worker_state.registered == true, "Worker is not available so can't unregister");
    //     require(isInBusyWorkers(msg.sender) == false, "Worker must be NOT Busy to unregister");
    //     uint256 now_ = getBlockTimestamp();
    //     //////////////////////////////////
    //     PopFromAvailableWorkers(msg.sender);
    //     PopFromBusyWorkers(msg.sender);
    //     worker_state.worker_address = msg.sender;
    //     worker_state.master_address = msg.sender;
    //     worker_state.last_interaction_date = now_;
    //     worker_state.registered = false;

    //     AllTxsCounter += 1;
    //     emit _WorkerUnregistered(msg.sender, now_);
    // }


    ///////////////  ---------------------------------------------------------------------
    ///////////////              INPUT FROM PREVIOUS DATA SYSTEM: CHECKED SPOT BATCHES
    ///////////////  ---------------------------------------------------------------------

    function Ping(uint256 CheckedBatchId) public returns(bool){
        if(FormattingSystem != IFormattingSystem(address(0)) && !CollectedFormatBatchs[CheckedBatchId]){           // don't re import already collected batch 

            if( FormattingSystem.DataExists(CheckedBatchId)){                
                IFormattingSystem.BatchMetadata memory FormatBatch = FormattingSystem.getBatchByID(CheckedBatchId);
                IFormattingSystem.DataStatus FormatBatchStatus = FormatBatch.status;
                // If SpotSystem has produced a new APPROVED DATA BATCH, process it in this system. 
                if(FormatBatchStatus == IFormattingSystem.DataStatus.APPROVED){
                    // -------- ADDING NEW CHECKED SPOT BATCH AS A NEW ITEM IN OUR FORMATTING BATCH --------


                    ArchiveMapping[DataNonce] = ArchiveData({
                        ipfs_hash: FormatBatch.batchIPFSfile,
                        author: msg.sender,
                        timestamp: block.timestamp,
                        status: DataStatus.TBD
                    });

                    DataNonce = DataNonce + 1;
                    emit _DataArchive(DataNonce, FormatBatch.batchIPFSfile, msg.sender);
                       
                }    
                // }
                CollectedFormatBatchs[CheckedBatchId] = true;
            }            
        
        }
        AllTxsCounter += 1;
        return false;
    }


    function deleteMapping(uint256 _CheckedBatchId)
    public
    onlyOwner
    {
        if(CollectedFormatBatchs[_CheckedBatchId]){
            delete CollectedFormatBatchs[_CheckedBatchId];
        }
    }


    function deleteData(uint256 _DataId)
    public
    onlyOwner
    {
        delete ArchiveMapping[_DataId];
    }


    // function TriggerUpdate() public topUpSFuel {
    //     // Log off waiting users first
    //     if(toUnregisterWorkers.length > 0){
    //         processLogoffRequests();
    //     }        
    //     for(uint256 i=0; i< Parameters.get_MAX_UPDATE_ITERATIONS() ;i++){
    //         bool progress = false;
    //         // IF CURRENT BATCH IS ALLOCATED TO WORKERS AND VOTE HAS ENDED, THEN CHECK IT & MOVE ON!
    //         if(DataBatch[BatchCheckingCursor].allocated_to_work == true && ( DataEnded(BatchCheckingCursor) || ( DataBatch[BatchCheckingCursor].unrevealed_workers == 0 ) )){
    //             ValidateDataBatch(BatchCheckingCursor);            
    //             BatchCheckingCursor = BatchCheckingCursor.add(1);        
    //             progress = true;
    //         }
    //         // IF CURRENT BATCH IS COMPLETE AND NOT ALLOCATED TO WORKERS TO BE CHECKED, THEN ALLOCATE!
    //         if( DataBatch[AllocatedBatchCursor].allocated_to_work != true  
    //             && availableWorkers.length >= Parameters.get_FORMAT_MIN_CONSENSUS_WORKER_COUNT()
    //             && DataBatch[AllocatedBatchCursor].complete  ){ //nothing to allocate, waiting for this to end
    //             AllocateWork();
    //             progress = true;
    //         }
    //         if(!progress){
    //             // break from the loop if no more progress is made when iterating (no batch to validate, no work to allocate)
    //             break;
    //         }
    //     }
    // }


    function AreStringsEqual(string memory _a, string memory _b) public pure returns(bool){
        if (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b))) {
            return true;
        }
        else{
            return false;
        }
    }
    event BytesFailure(bytes bytesFailure);

    // /**
    // @notice Trigger the validation of a FormattedData hash; if the FormattedData has ended. If the requirements are APPROVED, 
    // the CheckedData will be added to the APPROVED list of SpotCheckings
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // */
    // function ValidateDataBatch(uint256 _DataBatchId) public {
    //     require( DataEnded(_DataBatchId) || ( DataBatch[_DataBatchId].unrevealed_workers == 0 ), "_DataBatchId has not ended, or not every voters have voted"); // votes needs to be closed
    //     require( DataBatch[_DataBatchId].checked == false, "_DataBatchId is already validated"); // votes needs to be closed
    //     if(DataBatch[_DataBatchId].checked == false){                
    //         bool isCheckPassed = isPassed(_DataBatchId);
    //         address[] memory allocated_workers = WorkersPerBatch[_DataBatchId];
    //         string[] memory proposedNewFiles = new string[](allocated_workers.length);
            
    //         // -------------------------------------------------------------
    //         // assess result of the vote
    //         for (uint256 i = 0; i < allocated_workers.length; i++) {
    //             address worker_addr_ = allocated_workers[i];
    //             uint256 worker_vote_ = UserVotes[_DataBatchId][worker_addr_];
    //             bool has_worker_voted_ = UserChecksReveals[worker_addr_][_DataBatchId];  

    //             //  ASSESS WHAT IS THE MAJORITY VOTE ON THE NEW FILEHASH
    //             string memory worker_proposed_new_file_ = UserNewFiles[_DataBatchId][worker_addr_];
    //             proposedNewFiles[i] = worker_proposed_new_file_;
            
    //             // Worker state update
    //             //// because was busy a task, remove the worker from the busy pool
    //             PopFromBusyWorkers(worker_addr_);
    //             WorkerState storage worker_state = WorkersState[worker_addr_];

    //             if(has_worker_voted_){
    //                 // mark that worker has completed job, no matter the reward
    //                 WorkersState[worker_addr_].has_completed_work = true;
    //                 if( (isCheckPassed == true && worker_vote_ == 1)
    //                     || (isCheckPassed == false && worker_vote_ != 1) ){
    //                     // vote 1 == OK, else = NOT OK, rejected     
    //                     // reward worker if he voted like the majority             
    //                     require(RepManager.mintReputationForWork(MIN_REP_Data, worker_addr_, ""), "could not reward REP in TriggerCheckSpot, 1.a");
    //                     require(RewardManager.ProxyAddReward(MIN_REWARD_Data, worker_addr_), "could not reward token in TriggerCheckSpot, 1.b");
    //                 }
    //                 // mark worker back available, removed from the busy list
    //                 if(worker_state.registered){ // only if the worker is still registered, of course.
    //                     if(!isInAvailableWorkers(worker_addr_)){
    //                         availableWorkers.push(worker_addr_);
    //                     }
    //                 }
    //             }
    //             // if worker has not voted, he is disconnected "by force"
    //             // this worker will have to register again
    //             else{            
    //                 if(worker_state.registered){ // only if the worker is still registered
    //                     worker_state.registered = false;
    //                     PopFromAvailableWorkers(worker_addr_);
    //                     PopFromBusyWorkers(worker_addr_);
    //                 }
    //             }
    //         }
    //         // -------------------------------------------------------------
    //         // GET THE MAJORITY NEW HASH IPFS FILE
    //         uint256 majority_min_count = Math.max(allocated_workers.length * 50 / 100, 1);
    //         string memory majorityNewFile = proposedNewFiles[0]; //take first file by default, just in case
    //         for(uint256 k = 0; k < proposedNewFiles.length; k++){
    //             // count if this given New File is submitted by a majority
    //             uint256 counter = 0;
    //             for(uint256 l = 0; l < proposedNewFiles.length; l++){            
    //                 if(AreStringsEqual(proposedNewFiles[k], proposedNewFiles[l])){
    //                     counter += 1;
    //                     if(counter >= majority_min_count){
    //                         break;
    //                     }
    //                 }
    //             }
    //             if(counter >= majority_min_count){
    //                 majorityNewFile = proposedNewFiles[k];
    //                 break;
    //             }       
    //         }

    //         // -------------------------------------------------------------
    //         // BATCH STATE UPDATE: mark it checked, final.
    //         DataBatch[_DataBatchId].checked = true;
    //         DataBatch[_DataBatchId].batchIPFSfile = majorityNewFile;
    //         // -------------------------------------------------------------
    //         // IF THE DATA BLOCK IS ACCEPTED
    //         if(isCheckPassed){           
    //             //reward Spotter         
    //             require(RepManager.mintReputationForWork(MIN_REP_Data, ArchiveMapping[_DataBatchId].author, ""), "could not reward REP in TriggerCheckSpot, 2.a");
    //             require(RewardManager.ProxyAddReward(MIN_REWARD_Data, ArchiveMapping[_DataBatchId].author), "could not reward token in TriggerCheckSpot, 2.b");
    //             DataBatch[_DataBatchId].status = DataStatus.APPROVED;

    //             // try ArchiveSystem.Ping(_DataBatchId) returns(bool) {
    //             //     AllTxsCounter += 1;
    //             // } catch(bytes memory err) {
    //             //     emit BytesFailure(err);
    //             // }
    //         }
    //         // -------------------------------------------------------------
    //         // IF THE DATA BLOCK IS REJECTED
    //         else{        
    //             DataBatch[_DataBatchId].status = DataStatus.REJECTED;
    //         }

    //         // ---------------- GLOBAL STATE UPDATE ----------------
    //         AllTxsCounter += 1;

    //         emit _FormatAccepted(ArchiveMapping[_DataBatchId].ipfs_hash, ArchiveMapping[_DataBatchId].author);
    //     }
    // }
    


    // /* 
    // Allocate last data batch to be checked by K out N currently available workers.
    //  */
    // function AllocateWork() public  {
    //     require(DataBatch[AllocatedBatchCursor].complete, "Can't allocate work, the current batch is not complete");
    //     require(DataBatch[AllocatedBatchCursor].allocated_to_work == false, "Can't allocate work, the current batch is already allocated");
    //     uint256 selected_k = Math.max( Math.min(availableWorkers.length, CONSENSUS_WORKER_SIZE), 1); // pick at most CONSENSUS_WORKER_SIZE workers, minimum 1.
    //     uint256 n = availableWorkers.length;

    //     ///////////////////////////// BATCH UPDATE STATE /////////////////////////////
    //     DataBatch[AllocatedBatchCursor].unrevealed_workers = selected_k;
        
    //     uint256 _commitEndDate = block.timestamp.add(COMMIT_ROUND_DURATION);
    //     uint256 _revealEndDate = _commitEndDate.add(REVEAL_ROUND_DURATION);
    //     DataBatch[AllocatedBatchCursor].commitEndDate = _commitEndDate;
    //     DataBatch[AllocatedBatchCursor].revealEndDate = _revealEndDate;
    //     DataBatch[AllocatedBatchCursor].allocated_to_work = true;
    //     //////////////////////////////////////////////////////////////////////////////
        
    //     require(selected_k>=1 && n>=1, "Fail during allocation: not enough workers");
    //     uint256[] memory selected_workers_idx = random_selection(selected_k, n);
    //     address[] memory selected_workers_addresses = new address[](selected_workers_idx.length);
    //     for(uint i = 0; i<selected_workers_idx.length; i++){
    //         selected_workers_addresses[i] = availableWorkers[ selected_workers_idx[i] ];
    //     }
    //     for(uint i = 0; i<selected_workers_idx.length; i++){      
    //         address selected_worker_ = selected_workers_addresses[i];
    //         WorkerState storage worker_state = WorkersState[selected_worker_];
    //         ///// worker swapping from available to busy, not to be picked again while working.        
    //         PopFromAvailableWorkers(selected_worker_);    
    //         if(!isInBusyWorkers(selected_worker_)){
    //             busyWorkers.push(selected_worker_); //set worker as busy
    //         }
    //         WorkersPerBatch[AllocatedBatchCursor].push(selected_worker_);
    //         ///// allocation
    //         worker_state.allocated_work_batch = AllocatedBatchCursor;
    //         worker_state.has_completed_work = false;
    //         emit _WorkAllocated(AllocatedBatchCursor, selected_worker_);
    //     }
    //     AllocatedBatchCursor = AllocatedBatchCursor.add(1);
    //     AllTxsCounter += 1;
    // }

    // /* To know if new work is available for worker's address user_ */
    // function IsNewWorkAvailable(address user_) public view returns(bool) {
    //     bool new_work_available = false;
    //     WorkerState memory user_state =  WorkersState[user_];
    //     if (user_state.has_completed_work == false && DataEnded(user_state.allocated_work_batch) == false ){
    //         new_work_available = true;
    //     }
    //     return new_work_available;
    // }

    // /* Get newest work */
    // function GetCurrentWork(address user_) public view returns(uint256) {
    //     WorkerState memory user_state =  WorkersState[user_];
    //     return user_state.allocated_work_batch;
    // }



    // ==============================================================================================================================
    // ====================================================== FORMATTING  =============================================================
    // ==============================================================================================================================


    // =================
    // VOTING INTERFACE:
    // =================

    // /**
    // @notice Commits Archive-check-vote using hash of choice and secret salt to conceal Archive-check-vote until reveal
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @param _secretHash Commit keccak256 hash of voter's choice and salt (tightly packed in this order)
    // // @ _prevDataID The ID of the FormattedData that the user has voted the maximum number of tokens in which is still less than or equal to numTokens
    // */
    // function commitArchiveCheck(uint256 _DataBatchId, bytes32 _secretHash, string memory newIPFSHash) public topUpSFuel {
    //     require(commitPeriodActive(_DataBatchId), "commit period needs to be open");
    //     require(GetCurrentWork(msg.sender) == _DataBatchId, "User needs to have been allocated the current data batch to commit on it");

    //     //_numTokens The number of tokens to be committed towards the target FormattedData
    //     uint256 _numTokens = MIN_STAKE;
        
    //     // if msg.sender doesn't have enough voting rights,
    //     // request for enough voting rights
    //     if (FormatStakedTokenBalance[msg.sender] < _numTokens) {
    //         uint256 remainder = _numTokens.sub(FormatStakedTokenBalance[msg.sender]);
    //         requestVotingRights(remainder);
    //     }

    //     // make sure msg.sender has enough voting rights
    //     require(FormatStakedTokenBalance[msg.sender] >= _numTokens, "user must have enough voting rights aka allocated stake");

    //     uint256 _prevDataID = 0;

    //     // Check if _prevDataID exists in the user's DLL or if _prevDataID is 0
    //     require(_prevDataID == 0 || dllMap[msg.sender].contains(_prevDataID),"Error:  _prevDataID exists in the user's DLL or if _prevDataID is 0");

    //     uint256 nextDataID = dllMap[msg.sender].getNext(_prevDataID);

    //     // edge case: in-place update
    //     if (nextDataID == _DataBatchId) {
    //         nextDataID = dllMap[msg.sender].getNext(_DataBatchId);
    //     }

    //     require(validPosition(_prevDataID, nextDataID, msg.sender, _numTokens), "not a valid position");
    //     dllMap[msg.sender].insert(_prevDataID, _DataBatchId, nextDataID);

    //     bytes32 UUID = attrUUID(msg.sender, _DataBatchId);
        
    //     string memory nt = "numTokens";
        
    //     store.setAttribute(UUID,  nt, _numTokens);
    //     store.setAttribute(UUID, "commitHash", uint256(_secretHash));
    //     UserNewFiles[_DataBatchId][msg.sender] = newIPFSHash;

    //     // WORKER STATE UPDATE
    //     WorkerState storage worker_state = WorkersState[msg.sender];
    //     worker_state.last_interaction_date = getBlockTimestamp();    
    //     UserChecksCommits[msg.sender][_DataBatchId] = true;

    //     AllTxsCounter += 1;
    //     emit _ArchiveCheckCommitted(_DataBatchId, _numTokens, msg.sender);
    // }
    

    // /**
    // @notice                 Commits Archive-check-votes using hashes of choices and secret salts to conceal Archive-check-votes until reveal
    // @param _DataBatchIDs         Array of integer identifiers associated with target Datas
    // @param _secretHashes    Array of commit keccak256 hashes of voter's choices and salts (tightly packed in this order)
    // */
    // function commitArchiveChecks(uint256[] calldata  _DataBatchIDs, bytes32[] calldata _secretHashes, string[] calldata _newIPFSHash) external {
    //     // make sure the array lengths are all the same
        
    //     require(_DataBatchIDs.length == _secretHashes.length, "Error when commitArchiveChecks: _DataBatchIDs.length == _secretHashes.length");
    //     // loop through arrays, committing each individual Archive-check-vote values
    //     for (uint256 i = 0; i < _DataBatchIDs.length; i++) {
    //         commitArchiveCheck(_DataBatchIDs[i], _secretHashes[i], _newIPFSHash[i]);
    //     }
    // }

    // /**
    // @notice Reveals Archive-check-vote with choice and secret salt used in generating commitHash to attribute committed tokens
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @param _voteOption ArchiveCheck choice used to generate commitHash for associated FormattedData
    // @param _salt Secret number used to generate commitHash for associated FormattedData
    // */
    // function revealArchiveCheck(uint256 _DataBatchId, uint256 _voteOption, uint256 _salt) topUpSFuel public {
    //     // Make sure the reveal period is active
    //     require(revealPeriodActive(_DataBatchId), "Reveal period not open for this DataID");
    //     require(UserChecksCommits[msg.sender][_DataBatchId], "User has not commited before, thus can't reveal");
    //     require(getEncryptedVoteHash(_voteOption, _salt) == getCommitHash(msg.sender, _DataBatchId),
    //     "Not the same vote than what was commited, impossible to match with given _salt & _voteOption"); // compare resultant hash from inputs to original commitHash
        
    //     uint256 numTokens = getNumTokens(msg.sender, _DataBatchId);

    //     if (_voteOption == 1) {// apply numTokens to appropriate FormattedData choice
    //         DataBatch[_DataBatchId].votesFor += numTokens;
    //     } else {
    //         DataBatch[_DataBatchId].votesAgainst += numTokens;
    //     }

    //     // ----------------------- USER STATE UPDATE -----------------------
    //     dllMap[msg.sender].remove(_DataBatchId); // remove the node referring to this Archive-check-vote upon reveal
    //     UserChecksReveals[msg.sender][_DataBatchId] = true;
    //     UserVotes[_DataBatchId][msg.sender] = _voteOption;
        
    //     // ----------------------- WORKER STATE UPDATE -----------------------
    //     WorkerState storage worker_state = WorkersState[msg.sender];
    //     DataBatch[_DataBatchId].unrevealed_workers = DataBatch[_DataBatchId].unrevealed_workers.sub(1);
    //     worker_state.has_completed_work = true;
    //     worker_state.last_interaction_date = getBlockTimestamp();   

    //     // PUT BACK THE WORKER AS AVAILABLE
    //     PopFromBusyWorkers(msg.sender);
        
    //     if(!isInAvailableWorkers(msg.sender)){
    //         availableWorkers.push(msg.sender);
    //     }
 

    //     // // If that was the last worker to reveal, then go directly to Validation
    //     // if( DataBatch[_DataBatchId].unrevealed_workers == 0 ){
    //     //     ValidateDataBatch(_DataBatchId);
    //     // }
    //     AllTxsCounter += 1;
    //     emit _ArchiveCheckRevealed(_DataBatchId, numTokens, DataBatch[_DataBatchId].votesFor, DataBatch[_DataBatchId].votesAgainst, _voteOption, msg.sender);
    // }

    // /**
    // @notice             Reveals multiple Archive-check-votes with choices and secret salts used in generating commitHashes to attribute committed tokens
    // @param _DataBatchIDs     Array of integer identifiers associated with target Datas
    // @param _voteOptions Array of Archive-check-vote choices used to generate commitHashes for associated Datas
    // @param _salts       Array of secret numbers used to generate commitHashes for associated Datas
    // */
    // function revealArchiveChecks(uint256[] calldata _DataBatchIDs, uint256[] calldata _voteOptions, uint256[] calldata _salts) external {
    //     // make sure the array lengths are all the same
    //     require(_DataBatchIDs.length == _voteOptions.length, "Error revealArchiveChecks: _DataBatchIDs.length and _voteOptions.length must be equal");
    //     require(_DataBatchIDs.length == _salts.length, "Error revealArchiveChecks: _DataBatchIDs.length and _salts.length must be equal");

    //     // loop through arrays, revealing each individual Archive-check-vote values
    //     for (uint256 i = 0; i < _DataBatchIDs.length; i++) {
    //         revealArchiveCheck(_DataBatchIDs[i], _voteOptions[i], _salts[i]);
    //     }
    // }


    // ================================================================================
    //                              STAKING & TOKEN INTERFACE
    // ================================================================================

    // /**
    // @notice Loads _numTokens ERC20 tokens into the voting contract for one-to-one voting rights
    // @dev Assumes that msg.sender has approved voting contract to spend on their behalf
    // @param _numTokens The number of votingTokens desired in exchange for ERC20 tokens
    // */
    // function requestVotingRights(uint256 _numTokens) public {
    //     require(StakeManager.ProxyStakeAllocate(_numTokens, msg.sender), "Could not request enough allocated stake, requestVotingRights");
    //     FormatStakedTokenBalance[msg.sender] += _numTokens;
    //     emit _VotingRightsGranted(_numTokens, msg.sender);
    // }
    
    
    // /**
    // @notice Withdraw _numTokens ERC20 tokens from the voting contract, revoking these voting rights
    // @param _numTokens The number of ERC20 tokens desired in exchange for voting rights
    // */
    // function withdrawVotingRights(uint256 _numTokens) public {
    //     uint256 availableTokens = FormatStakedTokenBalance[msg.sender].sub(getLockedTokens(msg.sender));
    //     require(availableTokens >= _numTokens, "availableTokens should be >= _numTokens");
    //     require(StakeManager.ProxyStakeDeallocate(_numTokens, msg.sender), "Could not withdrawVotingRights through ProxyStakeDeallocate");
    //     FormatStakedTokenBalance[msg.sender] -= _numTokens;
    //     emit _VotingRightsWithdrawn(_numTokens, msg.sender);
    // }


    // /**
    // @dev Unlocks tokens locked in unrevealed Archive-check-vote where FormattedData has ended
    // @param _DataBatchId Integer identifier associated with the target FormattedData
    // */
    // function rescueTokens(uint256 _DataBatchId) public {
    //     require(DataBatch[_DataBatchId].status == DataStatus.APPROVED, "given DataBatch should be APPROVED, and it is not");
    //     require(dllMap[msg.sender].contains(_DataBatchId), "dllMap: does not cointain _DataBatchId for the msg sender");

    //     dllMap[msg.sender].remove(_DataBatchId);
    //     emit _TokensRescued(_DataBatchId, msg.sender);
    // }

    // /**
    // @dev Unlocks tokens locked in unrevealed Archive-check-votes where Datas have ended
    // @param _DataBatchIDs Array of integer identifiers associated with the target Datas
    // */
    // function rescueTokensInMultipleDatas(uint256[] memory _DataBatchIDs) public {
    //     // loop through arrays, rescuing tokens from all
    //     for (uint256 i = 0; i < _DataBatchIDs.length; i++) {
    //         rescueTokens(_DataBatchIDs[i]);
    //     }
    // }

    

    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    //                              STATE Getters
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------------------------------------------

    
    // function getIPFShashesForBatch(uint256 _DataBatchId) public view returns (string[] memory)  {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");
    //     BatchMetadata memory batch_ = DataBatch[_DataBatchId];
    //     uint256 batch_size = batch_.counter;

    //     string[] memory ipfs_hash_list = new string[](DATA_BATCH_SIZE);

    //     for(uint256 i=0; i < batch_size; i++){
    //         uint256 k = batch_.start_idx + i;
    //         string memory ipfs_hash_ = ArchiveMapping[k].ipfs_hash;
    //         ipfs_hash_list[i] = ipfs_hash_;
    //     }

    //     return ipfs_hash_list;
    // }


    // // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // //                              Data HELPERS
    // // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // // --------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // function getActiveWorkersCount() public view returns (uint256 numWorkers) {
    //     return(uint256(availableWorkers.length+busyWorkers.length));
    // }


    // /**
    // @dev Compares previous and next FormattedData's committed tokens for sorting purposes
    // @param _prevID Integer identifier associated with previous FormattedData in sorted order
    // @param _nextID Integer identifier associated with next FormattedData in sorted order
    // @param _voter Address of user to check DLL position for
    // @param _numTokens The number of tokens to be committed towards the FormattedData (used for sorting)
    // @return APPROVED Boolean indication of if the specified position maintains the sort
    // */
    // function validPosition(uint256 _prevID, uint256 _nextID, address _voter, uint256 _numTokens) public view returns (bool APPROVED) {
    //     bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
    //     // if next is zero node, _numTokens does not need to be greater
    //     bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
    //     return prevValid && nextValid;
    // }


    // /**
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @param _salt Arbitrarily chosen integer used to generate secretHash
    // @return correctArchiveChecks Number of tokens voted for winning option
    // */
    // function getNumPassingTokens(address _voter, uint256 _DataBatchId, uint256 _salt) public view returns (uint256 correctArchiveChecks) {
    //     require(DataEnded(_DataBatchId), "_DataBatchId checking vote must have ended");
    //     require(UserChecksReveals[_voter][_DataBatchId], "user must have revealed in this given Batch");
        

    //     uint256 winningChoice = isPassed(_DataBatchId) ? 1 : 0;
    //     bytes32 winnerHash = keccak256(abi.encodePacked(winningChoice, _salt));
    //     bytes32 commitHash = getCommitHash(_voter, _DataBatchId);

    //     require(winnerHash == commitHash, "getNumPassingTokens: hashes must be equal");

    //     return getNumTokens(_voter, _DataBatchId);
    // }

    
    // /**
    // @notice Trigger the validation of a FormattedData hash; if the FormattedData has ended. If the requirements are APPROVED, 
    // the ArchiveChecking will be added to the APPROVED list of ArchiveCheckings
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // */
    // function getTotalNumberOfArchiveChecks(uint256 _DataBatchId) public view returns (uint256 vc)  {
    //     // Build ArchiveCheckings Struct
    //     uint256 token_vote_count = DataBatch[_DataBatchId].votesFor + DataBatch[_DataBatchId].votesAgainst;
    //     return token_vote_count;
    // }
    

    // /**
    // @notice Determines if proposal has passed
    // @dev Check if votesFor out of totalArchiveChecks exceeds votesQuorum (requires DataEnded)
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // */
    // function isPassed(uint256 _DataBatchId)  public view returns (bool passed) {
    //     // require(DataEnded(_DataBatchId), "Data Batch Checking commitee must have ended");

    //     BatchMetadata memory batch_ = DataBatch[_DataBatchId];
    //     return (100 * batch_.votesFor) > (SPOT_CHECK_VOTE_QUORUM * (batch_.votesFor + batch_.votesAgainst));
    // }

    // /**
    // @dev Gets the total winning Archive-check-votes for reward distribution purposes
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return numTokens of Archive-check-votes committed to the winning option for specified FormattedData
    // */
    // function getTotalNumberOfTokensForWinningOption(uint256 _DataBatchId) public view returns (uint256 numTokens) {
    //     require(DataEnded(_DataBatchId), "Data must have ended");

    //     if (isPassed(_DataBatchId))
    //         return DataBatch[_DataBatchId].votesFor;
    //     else
    //         return DataBatch[_DataBatchId].votesAgainst;
    // }

    // /**
    // @notice Determines if FormattedData is over
    // @dev Checks isExpired for specified FormattedData's revealEndDate
    // @return ended Boolean indication of whether Dataing period is over
    // */
    // function DataEnded(uint256 _DataBatchId) public view returns (bool ended) {
    //     require(DataExists(_DataBatchId), "Data must exist");

    //     return isExpired(DataBatch[_DataBatchId].revealEndDate);
    // }
    
    
    /**
    @notice getLastDataId
    @return data of the id _DataID
    */
    function getDataById(uint256 _DataID) public view returns (ArchiveData memory data) {
        require(_DataID <= DataNonce);
        return  ArchiveMapping[_DataID];
    }

    /**
    @notice getLastDataId
    @return ipfs_hash of the last Dataed a user started
    */
    function getFileById(uint256 _DataID) public view returns (string memory ipfs_hash) {
        require(_DataID <= DataNonce);
        return  ArchiveMapping[_DataID].ipfs_hash;
    }

    /**
    @notice getLastDataId
    @return DataId of the last Dataed a user started
    */
    function getLastDataId() public view returns (uint256 DataId) {
        return  DataNonce;
    }

    // /**
    // @notice getLastBatchId
    // @return LastBatchId of the last Dataed a user started
    // */
    // function getLastBatchId() public view returns (uint256 LastBatchId) {
    //     return  LastBatchCounter;
    // }
    
    // /**
    // @notice getLastBachDataId
    // @return LastCheckedBatchId of the last Dataed a user started
    // */
    // function getLastCheckedBatchId() public view returns (uint256 LastCheckedBatchId) {
    //     return  BatchCheckingCursor;
    // }

    /**
    @notice getCounter
    @return Counter of the last Dataed a user started
    */
    function getTxCounter() public view returns (uint256 Counter) {
        return  AllTxsCounter;
    }
    

    // /**
    // @notice Determines DataCommitEndDate
    // @return commitEndDate indication of whether Dataing period is over
    // */
    // function DataCommitEndDate(uint256 _DataBatchId) public view returns (uint256 commitEndDate) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     return DataBatch[_DataBatchId].commitEndDate;
    // }
    
    
    // /**
    // @notice Determines DataRevealEndDate
    // @return revealEndDate indication of whether Dataing period is over
    // */
    // function DataRevealEndDate(uint256 _DataBatchId) public view returns (uint256 revealEndDate) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     return DataBatch[_DataBatchId].revealEndDate;
    // }
    
    // /**
    // @notice Checks if the commit period is still active for the specified FormattedData
    // @dev Checks isExpired for the specified FormattedData's commitEndDate
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return active Boolean indication of isCommitPeriodActive for target FormattedData
    // */
    // function commitPeriodActive(uint256 _DataBatchId) public view returns (bool active) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     return !isExpired(DataBatch[_DataBatchId].commitEndDate);
    // }

    // /**
    // @notice Checks if the reveal period is still active for the specified FormattedData
    // @dev Checks isExpired for the specified FormattedData's revealEndDate
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // */
    // function revealPeriodActive(uint256 _DataBatchId) public view returns (bool active) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     return !isExpired(DataBatch[_DataBatchId].revealEndDate) && !commitPeriodActive(_DataBatchId);
    // }

    // /**
    // @dev Checks if user has committed for specified FormattedData
    // @param _voter Address of user to check against
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return committed Boolean indication of whether user has committed
    // */
    // function didCommit(address _voter, uint256 _DataBatchId) public view returns (bool committed) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     // return ArchiveMapping[_DataBatchId].didCommit[_voter];
    //     return UserChecksCommits[_voter][_DataBatchId];
    // }

    // /**
    // @dev Checks if user has revealed for specified FormattedData
    // @param _voter Address of user to check against
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return revealed Boolean indication of whether user has revealed
    // */
    // function didReveal(address _voter, uint256 _DataBatchId) public view returns (bool revealed) {
    //     require(DataExists(_DataBatchId), "_DataBatchId must exist");

    //     // return ArchiveMapping[_DataBatchId].didReveal[_voter];
    //     return UserChecksReveals[_voter][_DataBatchId];
    // }

    /**
    @dev Checks if a FormattedData exists
    @param _DataId The DataID whose existance is to be evaluated.
    @return exists Boolean Indicates whether a FormattedData exists for the provided DataID
    */
    function DataExists(uint256 _DataId) public view returns  (bool exists) {
        return (_DataId <= DataNonce);
    }

    // function AmIRegistered()  public view returns (bool passed) {
    //     return WorkersState[msg.sender].registered;
    // }

    // function isWorkerRegistered(address _worker)  public view returns (bool passed) {
    //     return WorkersState[_worker].registered;
    // }


    // ------------------------------------------------------------------------------------------------------------
    // DOUBLE-LINKED-LIST HELPERS:
    // ------------------------------------------------------------------------------------------------------------

    // /**
    // @dev Gets the bytes32 commitHash property of target FormattedData
    // @param _voter Address of user to check against
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return commitHash Bytes32 hash property attached to target FormattedData
    // */
    // function getCommitHash(address _voter, uint256 _DataBatchId)  public view returns (bytes32 commitHash) {
    //     return bytes32(store.getAttribute(attrUUID(_voter, _DataBatchId), "commitHash"));
    // }


    // /**
    // @dev Gets the bytes32 commitHash property of target FormattedData
    // @param _voteOption vote Option
    // @param _salt is the salt
    // @return keccak256hash Bytes32 hash property attached to target FormattedData
    // */
    // function getEncryptedVoteHash(uint256 _voteOption, uint256 _salt)  public pure returns (bytes32 keccak256hash) {
    //     return keccak256(abi.encodePacked(_voteOption, _salt));
    // }


    // /**
    // @dev Gets the bytes32 commitHash property of target FormattedData
    // @param _hash ipfs hash of aggregated data
    // @param _salt is the salt
    // @return keccak256hash Bytes32 hash property attached to target FormattedData
    // */
    // function getEncryptedStringHash(string calldata _hash, uint256 _salt) public pure returns (bytes32 keccak256hash){
    //     return keccak256(abi.encode(_hash, _salt));
    // }

    // /**
    // @dev Wrapper for getAttribute with attrName="numTokens"
    // @param _voter Address of user to check against
    // @param _DataBatchId Integer identifier associated with target FormattedData
    // @return numTokens Number of tokens committed to FormattedData in sorted FormattedData-linked-list
    // */
    // function getNumTokens(address _voter, uint256 _DataBatchId)  public view returns (uint256 numTokens) {
    //     return store.getAttribute(attrUUID(_voter, _DataBatchId), "numTokens");
    // }

    // /**
    // @dev Gets top element of sorted FormattedData-linked-list
    // @param _voter Address of user to check against
    // @return DataID Integer identifier to FormattedData with maximum number of tokens committed to it
    // */
    // function getLastNode(address _voter)  public view returns (uint256 DataID) {
    //     return dllMap[_voter].getPrev(0);
    // }

    // /**
    // @dev Gets the numTokens property of getLastNode
    // @param _voter Address of user to check against
    // @return numTokens Maximum number of tokens committed in FormattedData specified
    // */
    // function getLockedTokens(address _voter)  public view returns (uint256 numTokens) {
    //     return getNumTokens(_voter, getLastNode(_voter));
    // }

    // /*
    // @dev Takes the last node in the user's DLL and iterates backwards through the list searching
    // for a node with a value less than or equal to the provided _numTokens value. When such a node
    // is found, if the provided _DataBatchId matches the found nodeID, this operation is an in-place
    // update. In that case, return the previous node of the node being updated. Otherwise return the
    // first node that was found with a value less than or equal to the provided _numTokens.
    // @param _voter The voter whose DLL will be searched
    // @param _numTokens The value for the numTokens attribute in the node to be inserted
    // @return the node which the propoded node should be inserted after
    // */
    // function getInsertPointForNumTokens(address _voter, uint256 _numTokens, uint256 _DataBatchId) public view  returns (uint256 prevNode) {
    //   // Get the last node in the list and the number of tokens in that node
    //   uint256 nodeID = getLastNode(_voter);
    //   uint256 tokensInNode = getNumTokens(_voter, nodeID);

    //   // Iterate backwards through the list until reaching the root node
    //   while(nodeID != 0) {
    //     // Get the number of tokens in the current node
    //     tokensInNode = getNumTokens(_voter, nodeID);
    //     if(tokensInNode <= _numTokens) { // We found the insert point!
    //       if(nodeID == _DataBatchId) {
    //         // This is an in-place update. Return the prev node of the node being updated
    //         nodeID = dllMap[_voter].getPrev(nodeID);
    //       }
    //       // Return the insert point
    //       return nodeID; 
    //     }
    //     // We did not find the insert point. Continue iterating backwards through the list
    //     nodeID = dllMap[_voter].getPrev(nodeID);
    //   }

    //   // The list is empty, or a smaller value than anything else in the list is being inserted
    //   return nodeID;
    // }

    // // ----------------
    // // GENERAL HELPERS:
    // // ----------------

    // /**
    // @dev Checks if an expiration date has been reached
    // @param _terminationDate Integer timestamp of date to compare current timestamp with
    // @return expired Boolean indication of whether the terminationDate has passed
    // */
    // function isExpired(uint256 _terminationDate)  public view returns (bool expired) {
    //     return (block.timestamp > _terminationDate);
    // }
    
    // /**
    // @return keccak256hash  Hash which is deterministic from a and b
    // */
    // function getHash(uint256 a, uint256 b) public pure returns (bytes32 keccak256hash) {
    //     return keccak256(abi.encodePacked(a, b));
    // }
    
    /**
    @return blocktimestamp block.timestamp
    */
    function getBlockTimestamp()  public view returns (uint256 blocktimestamp) {
        return block.timestamp;
    }


    /**
    @dev Generates an identifier which associates a user and a FormattedData together
    @param _DataBatchId Integer identifier associated with target FormattedData
    @return UUID Hash which is deterministic from _user and _DataBatchId
    */
    function attrUUID(address _user, uint256 _DataBatchId) public pure returns (bytes32 UUID) {
        return keccak256(abi.encodePacked(_user, _DataBatchId));
    }
}
