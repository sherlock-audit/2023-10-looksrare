// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ChainlinkHelpers {
    function _computeVrfRequestId(
        bytes32 keyHash,
        address sender,
        uint64 subId,
        uint64 nonce
    ) internal pure returns (uint256 requestId) {
        uint256 preSeed = uint256(keccak256(abi.encode(keyHash, sender, subId, nonce)));
        requestId = uint256(keccak256(abi.encode(keyHash, preSeed)));
    }
}
