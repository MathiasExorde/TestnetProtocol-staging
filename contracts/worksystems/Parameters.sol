// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title Parameters  v0.1
@author Mathias Dail
*/
contract Parameters is Ownable {
    // Default values
    //////////////// GENERAL SYSTEM PARAMTERS
    uint256 public MAX_TOTAL_WORKERS = 1000;
    uint256 public VOTE_QUORUM  = 50;   
    uint256 public MAX_UPDATE_ITERATIONS  = 50;   
    uint256 public MAX_CONTRACT_STORED_BATCHES  = 200000;   
    //////////////// SPOTTING RELATED PARAMETERS
    uint256 public SPOT_DATA_BATCH_SIZE = 1;
    uint256 public SPOT_MIN_STAKE = 25 * (10 ** 18); 
    uint256 public SPOT_MIN_CONSENSUS_WORKER_COUNT  = 2;   
    uint256 public SPOT_MAX_CONSENSUS_WORKER_COUNT  = 4;
    uint256 public SPOT_COMMIT_ROUND_DURATION = 180;
    uint256 public SPOT_REVEAL_ROUND_DURATION = 180;       
    uint256 public SPOT_MIN_REWARD_Data = 2 * (10 ** 18);
    uint256 public SPOT_MIN_REP_Data  = 40 * (10 ** 18);
    // SPOT DATA LIMITATIONS
    uint256 public SPOT_INTER_ALLOCATION_DURATION = 400;
    bool public SPOT_TOGGLE_ENABLED = true;
    uint256 public SPOT_TIMEFRAME_DURATION  = 15*60; //15 minutes
    uint256 public SPOT_GLOBAL_MAX_SPOT_PER_PERIOD  = 1000;
    uint256 public SPOT_MAX_SPOT_PER_USER_PER_PERIOD  = 25;
    uint256 public SPOT_NB_TIMEFRAMES = 4;
    uint256 public MAX_SUCCEEDING_NOVOTES  = 3;    
    uint256 public NOVOTE_REGISTRATION_WAIT_DURATION  = 3600;    // in seconds
    //////////////// FORMATTING RELATED PARAMETERS
    uint256 public FORMAT_DATA_BATCH_SIZE = 1; 
    uint256 public FORMAT_MIN_CONSENSUS_WORKER_COUNT  = 2; 
    uint256 public FORMAT_MAX_CONSENSUS_WORKER_COUNT  = 4;   
    uint256 public FORMAT_MIN_STAKE = 25 * (10 ** 18); 
    uint256 public FORMAT_COMMIT_ROUND_DURATION = 400;
    uint256 public FORMAT_REVEAL_ROUND_DURATION = 180;  
    uint256 public FORMAT_MIN_REWARD_Data = 3 * (10 ** 18);
    uint256 public FORMAT_MIN_REP_Data  = 50 * (10 ** 18);
    //////////////// CONTRACTS
    address public token;
    address public StakeManager;
    address public RepManager;
    address public RewardManager;
    address public AddressManager;
    address public SpottingSystem;
    address public FormattingSystem;
    address public sFuel;

    
// for other contracts
// interface IParametersManager {
//       // -------------- GETTERS : GENERAL --------------------
//     function getMaxTotalWorkers() external view returns(uint256);
//     function getVoteQuorum() external view returns(uint256);
//     function get_MAX_UPDATE_ITERATIONS() external view returns(uint256);
//     function get_MAX_CONTRACT_STORED_BATCHES() external view returns(uint256);
//     function get_MAX_SUCCEEDING_NOVOTES() external view returns(uint256);
//     function get_NOVOTE_REGISTRATION_WAIT_DURATION() external view returns(uint256);
//     // -------------- GETTERS : ADDRESSES --------------------    
//     function getStakeManager() external view returns(address);
//     function getRepManager() external view returns(address);
//     function getRewardManager() external view returns(address);
//     function getSpottingSystem() external view returns(address);
//     function getFormattingSystem() external view returns(address);
//     function getsFuelSystem() external view returns(address);
//     function getExordeToken() external view returns(address);
//     // -------------- GETTERS : SPOTTING --------------------
//     function get_SPOT_DATA_BATCH_SIZE() external view returns(uint256);
//     function get_SPOT_MIN_STAKE() external view returns(uint256);
//     function get_SPOT_MIN_CONSENSUS_WORKER_COUNT() external view returns(uint256);
//     function get_SPOT_MAX_CONSENSUS_WORKER_COUNT() external view returns(uint256);
//     function get_SPOT_COMMIT_ROUND_DURATION() external view returns(uint256);
//     function get_SPOT_REVEAL_ROUND_DURATION() external view returns(uint256);
//     function get_SPOT_MIN_REP_Data() external view returns(uint256);
//     function get_SPOT_MIN_REWARD_Data() external view returns(uint256);
//     function get_SPOT_INTER_ALLOCATION_DURATION() external view returns(uint256);
//     function get_SPOT_TOGGLE_ENABLED() external view returns(bool);
//     function get_SPOT_TIMEFRAME_DURATION() external view returns(uint256);
//     function get_SPOT_GLOBAL_MAX_SPOT_PER_PERIOD() external view returns(uint256);
//     function get_SPOT_MAX_SPOT_PER_USER_PER_PERIOD() external view returns(uint256);
//     function get_SPOT_NB_TIMEFRAMES() external view returns(uint256);
//     // -------------- GETTERS : FORMATTING --------------------
//     function get_FORMAT_DATA_BATCH_SIZE() external view returns(uint256);
//     function get_FORMAT_MIN_STAKE() external view returns(uint256);
//     function get_FORMAT_MIN_CONSENSUS_WORKER_COUNT() external view returns(uint256);
//     function get_FORMAT_MAX_CONSENSUS_WORKER_COUNT() external view returns(uint256);
//     function get_FORMAT_COMMIT_ROUND_DURATION() external view returns(uint256);
//     function get_FORMAT_REVEAL_ROUND_DURATION() external view returns(uint256);
//     function get_FORMAT_MIN_REWARD_Data() external view returns(uint256);
//     function get_FORMAT_MIN_REP_Data() external view returns(uint256);
// }
    
    function updateGeneralParameters(uint256 ParameterIndex, uint256 uintValue) public onlyOwner {        
        if(ParameterIndex == 1){
            MAX_TOTAL_WORKERS = uintValue;
        }
        if(ParameterIndex == 2){
            VOTE_QUORUM  = uintValue;
        }
        if(ParameterIndex == 3){
            MAX_UPDATE_ITERATIONS  = uintValue;
        }
        if(ParameterIndex == 4){
            MAX_CONTRACT_STORED_BATCHES  = uintValue;
        }
    }


    function updateContractsAddresses(address StakeManager_, address RepManager_, address RewardManager_, address AddressManager_,
                                      address SpottingSystem_, address FormattingSystem_, address sFuel_, address token_) public  onlyOwner {
        if(StakeManager_ != address(0)){
            StakeManager = StakeManager_;
        }
        if(RepManager_ != address(0)){
            RepManager = RepManager_;
        }
        if(RewardManager_ != address(0)){
            RewardManager = RewardManager_;
        }
        if(AddressManager_ != address(0)){
            AddressManager = AddressManager_;
        }
        if(SpottingSystem_ != address(0)){
            SpottingSystem = SpottingSystem_;
        }
        if(FormattingSystem_ != address(0)){
            FormattingSystem = FormattingSystem_;
        }
        if(sFuel_ != address(0)){
            sFuel = sFuel_;
        }
        if(token_ != address(0)){
            token = token_;
        }
    }

    
    
    function updateSpottingParameters(uint256 ParameterIndex, uint256 uintValue, bool boolValue) public onlyOwner {        
        if(ParameterIndex == 1){
            SPOT_DATA_BATCH_SIZE  = uintValue;
        }
        if(ParameterIndex == 2){
            SPOT_MIN_STAKE  = uintValue;
        }
        if(ParameterIndex == 3){
            SPOT_MIN_CONSENSUS_WORKER_COUNT  = uintValue;
        }
        if(ParameterIndex == 4){
            SPOT_MAX_CONSENSUS_WORKER_COUNT  = uintValue;
        }
        if(ParameterIndex == 5){
            SPOT_COMMIT_ROUND_DURATION  = uintValue;
        }
        if(ParameterIndex == 6){
            SPOT_REVEAL_ROUND_DURATION  = uintValue;
        }
        if(ParameterIndex == 7){
            SPOT_MIN_REWARD_Data  = uintValue;
        }
        if(ParameterIndex == 8){
            SPOT_MIN_REP_Data  = uintValue;
        }
        // Spotting DataInput Management system
        if(ParameterIndex == 9){
            SPOT_INTER_ALLOCATION_DURATION = uintValue;
        }
        if(ParameterIndex == 10){
            SPOT_TOGGLE_ENABLED = boolValue;
        }
        if(ParameterIndex == 11){
            SPOT_TIMEFRAME_DURATION = uintValue;
        }
        if(ParameterIndex == 12){
            SPOT_GLOBAL_MAX_SPOT_PER_PERIOD = uintValue;
        }
        if(ParameterIndex == 13){
            SPOT_MAX_SPOT_PER_USER_PER_PERIOD = uintValue;
        }
        if(ParameterIndex == 14){
            SPOT_NB_TIMEFRAMES = uintValue;
        }
        if(ParameterIndex == 15){
            MAX_SUCCEEDING_NOVOTES = uintValue;
        }
        if(ParameterIndex == 16){
            NOVOTE_REGISTRATION_WAIT_DURATION = uintValue;
        }
    }


    function updateFormattingParameters(uint256 ParameterIndex, uint256 uintValue) public onlyOwner {        
        if(ParameterIndex == 1){
            FORMAT_DATA_BATCH_SIZE = uintValue;
        }
        if(ParameterIndex == 2){
            FORMAT_MIN_STAKE  = uintValue;
        }
        if(ParameterIndex == 3){
            FORMAT_MIN_CONSENSUS_WORKER_COUNT  = uintValue;
        }
        if(ParameterIndex == 4){
            FORMAT_MAX_CONSENSUS_WORKER_COUNT  = uintValue;
        }
        if(ParameterIndex == 5){
            FORMAT_COMMIT_ROUND_DURATION  = uintValue;
        }
        if(ParameterIndex == 6){
            FORMAT_REVEAL_ROUND_DURATION  = uintValue;
        }
        if(ParameterIndex == 7){
            FORMAT_MIN_REWARD_Data  = uintValue;
        }
        if(ParameterIndex == 8){
            FORMAT_MIN_REP_Data  = uintValue;
        }
    }


    // -------------- GETTERS : GENERAL --------------------
    function getMaxTotalWorkers() public view returns(uint256){
        return MAX_TOTAL_WORKERS;
    }
    function getVoteQuorum() public view returns(uint256){
        return VOTE_QUORUM;
    }
    function get_MAX_UPDATE_ITERATIONS() public view returns(uint256){
        return MAX_UPDATE_ITERATIONS;
    }
    function get_MAX_CONTRACT_STORED_BATCHES() public view returns(uint256){
        return MAX_CONTRACT_STORED_BATCHES;
    }

    // -------------- GETTERS : ADDRESSES --------------------    
    function getStakeManager() public view returns(address){
        return StakeManager;
    }
    function getRepManager() public view returns(address){
        return RepManager;
    }
    function getRewardManager() public view returns(address){
        return RewardManager;
    }    
    function getSpottingSystem() public view returns(address){
        return SpottingSystem;
    }
    function getFormattingSystem() public view returns(address){
        return FormattingSystem;
    }
    function getsFuelSystem() public view returns(address){
        return sFuel;
    }
    function getExordeToken() public view returns(address){
        return token;
    }

    // -------------- GETTERS : SPOTTING --------------------
    function get_SPOT_DATA_BATCH_SIZE() public view returns(uint256){
        return SPOT_DATA_BATCH_SIZE;
    }
    function get_SPOT_MIN_STAKE() public view returns(uint256){
        return SPOT_MIN_STAKE;
    }
    function get_SPOT_MIN_CONSENSUS_WORKER_COUNT() public view returns(uint256){
        return SPOT_MIN_CONSENSUS_WORKER_COUNT;
    }
    function get_SPOT_MAX_CONSENSUS_WORKER_COUNT() public view returns(uint256){
        return SPOT_MAX_CONSENSUS_WORKER_COUNT;
    }
    function get_SPOT_COMMIT_ROUND_DURATION() public view returns(uint256){
        return SPOT_COMMIT_ROUND_DURATION;
    }
    function get_SPOT_REVEAL_ROUND_DURATION() public view returns(uint256){
        return SPOT_REVEAL_ROUND_DURATION;
    }
    function get_SPOT_MIN_REP_Data() public view returns(uint256){
        return SPOT_MIN_REP_Data;
    }
    function get_SPOT_MIN_REWARD_Data() public view returns(uint256){
        return SPOT_MIN_REWARD_Data;
    }
    function get_SPOT_INTER_ALLOCATION_DURATION() public view returns(uint256){
        return SPOT_INTER_ALLOCATION_DURATION;
    }
    function get_SPOT_TOGGLE_ENABLED() public view returns(bool){
        return SPOT_TOGGLE_ENABLED;
    }    
    function get_SPOT_TIMEFRAME_DURATION() public view returns(uint256){
        return SPOT_TIMEFRAME_DURATION;
    }    
    function get_SPOT_GLOBAL_MAX_SPOT_PER_PERIOD() public view returns(uint256){
        return SPOT_GLOBAL_MAX_SPOT_PER_PERIOD;
    }    
    function get_SPOT_MAX_SPOT_PER_USER_PER_PERIOD() public view returns(uint256){
        return SPOT_MAX_SPOT_PER_USER_PER_PERIOD;
    }
    function get_SPOT_NB_TIMEFRAMES() public view returns(uint256){
        return SPOT_NB_TIMEFRAMES;
    }
    function get_MAX_SUCCEEDING_NOVOTES() public view returns(uint256){
        return MAX_SUCCEEDING_NOVOTES;
    }
    function get_NOVOTE_REGISTRATION_WAIT_DURATION() public view returns(uint256){
        return NOVOTE_REGISTRATION_WAIT_DURATION;
    }

    // -------------- GETTERS : FORMATTING --------------------
    function get_FORMAT_DATA_BATCH_SIZE() public view returns(uint256){
        return FORMAT_DATA_BATCH_SIZE;
    }
    function get_FORMAT_MIN_STAKE() public view returns(uint256){
        return FORMAT_MIN_STAKE;
    }
    function get_FORMAT_MIN_CONSENSUS_WORKER_COUNT() public view returns(uint256){
        return FORMAT_MIN_CONSENSUS_WORKER_COUNT;
    }
    function get_FORMAT_MAX_CONSENSUS_WORKER_COUNT() public view returns(uint256){
        return FORMAT_MAX_CONSENSUS_WORKER_COUNT;
    }
    function get_FORMAT_COMMIT_ROUND_DURATION() public view returns(uint256){
        return FORMAT_COMMIT_ROUND_DURATION;
    }
    function get_FORMAT_REVEAL_ROUND_DURATION() public view returns(uint256){
        return FORMAT_REVEAL_ROUND_DURATION;
    }
    function get_FORMAT_MIN_REWARD_Data() public view returns(uint256){
        return FORMAT_MIN_REWARD_Data;
    }
    function get_FORMAT_MIN_REP_Data() public view returns(uint256){
        return FORMAT_MIN_REP_Data;
    }
}
