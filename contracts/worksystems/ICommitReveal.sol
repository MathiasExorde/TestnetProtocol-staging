// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

interface ICommitReveal {
    function commitFileVote(
        uint128 _DataBatchId,
        bytes32 _encryptedHash,
        bytes32 _encryptedVote,
        uint32 _BatchCount,
        string memory _From
    ) external;

    function revealFileVote(
        uint64 _DataBatchId,
        string memory _clearIPFSHash,
        uint8 _clearVote,
        uint256 _salt
    ) external;
}

