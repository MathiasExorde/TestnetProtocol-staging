// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract RandomAllocator {

    /**
    @dev Initializer. Can only be called once.
    */
    // constructor() public  {
    //     for(uint256 i=0; i<5; i++){
    //         subsystems_seeds[i] = getRandom() + uint256(keccak256(abi.encodePacked(i)));
    //     }
    // }
    

    function getSeed() public view returns (bytes32 addr) {
        assembly {
            let freemem := mload(0x40)
            let start_addr := add(freemem, 0)
            if iszero(staticcall(gas(), 0x18, 0, 0, start_addr, 32)) {
              invalid()
            }
            addr := mload(freemem)
        }
    }


    /**
     * @dev Return value
     * @return value of 'number'
     */
    function getRandom() public view returns (uint256){
        uint256 r = uint256(keccak256(abi.encodePacked(block.timestamp + uint256(keccak256(abi.encodePacked(getSeed()))) + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)))));
        return r;
    }


    /**
     * @dev Return value
     * @return value of 'number'
     */
     function generateIntegers(uint256 _k, uint256 N_range) public view returns (uint256[] memory){
        require(   N_range > 0 && _k <= N_range && _k >= 1 ,"k or N are not OK for RNG" );
        require(_k >= 1, "_k >= 0");
        require(N_range >= 1,"N_range > 0");
        uint256 seed = uint256(keccak256(abi.encodePacked(uint256(keccak256(abi.encodePacked(getRandom()))))));
        uint256[] memory integers = new uint256[](_k);

        uint256 c = 0;
        uint256 nb_iterations = _k + 20;

        for(uint256 l = 0; l < nb_iterations ; l++ ){
            uint256 randNumber = (uint256(keccak256(abi.encodePacked(seed+l*l)))) % N_range;
            bool already_exists = false;
            // check if already generated
            for(uint256 i = 0; i < c ; i++){
                if(integers[i] == randNumber){
                    already_exists = true;
                    break;
                }
            }
            if(!already_exists){
                integers[c] = randNumber;
                c = c + 1;
            }
            if( c >= _k){
                break;
            }
        }

        if ( c < _k ){
            for ( uint256 k = 0; k < N_range; k++ ){
                uint256 newNumber = k;
                bool already_exists = false;
                for(uint256 i = 0; i < c ; i++){
                    if(integers[i] == newNumber){
                        already_exists = true;
                        break;
                    }
                }
                if(!already_exists){
                    integers[c] = newNumber;
                    c = c + 1;
                }
                if( c >= _k){
                    break;
                }
            }
        }
        require(c == _k,"RNG insufficient");
        return integers;
    }


    function random_selection(uint256 k, uint256 N) public view returns(uint256[] memory){
        require(   N > 0 && k <= N && k >= 1 ,"k or N are not OK for RNG" );
        uint256[] memory resultArray = generateIntegers(k, N);
        return resultArray;
    }
}