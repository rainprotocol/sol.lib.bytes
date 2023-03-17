// SPDX-License-Identifier: CAL
pragma solidity ^0.8.16;

type Pointer is uint256;

/// @title LibMemory
/// @notice Tools for working directly with memory in a Solidity compatible way.
library LibMemory {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param source_ The starting location in memory to read from.
    /// @param target_ The starting location in memory to write to.
    /// @param length_ The number of bytes to read/write.
    function unsafeCopyBytesTo(Pointer source_, Pointer target_, uint256 length_) internal pure {
        assembly ("memory-safe") {
            for {} iszero(lt(length_, 0x20)) {
                length_ := sub(length_, 0x20)
                source_ := add(source_, 0x20)
                target_ := add(target_, 0x20)
            } { mstore(target_, mload(source_)) }

            if gt(length_, 0) {
                //slither-disable-next-line incorrect-shift
                let mask_ := shr(mul(length_, 8), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                // preserve existing bytes
                mstore(
                    target_,
                    or(
                        // input
                        and(mload(source_), not(mask_)),
                        and(mload(target_), mask_)
                    )
                )
            }
        }
    }

    /// Pointer to the data of a bytes array NOT the length prefix.
    function dataPointer(bytes memory data_) internal pure returns (Pointer pointer_) {
        assembly ("memory-safe") {
            pointer_ := add(data_, 0x20)
        }
    }
}
