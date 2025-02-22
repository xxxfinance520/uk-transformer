// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IOmniverseUKTransformerBeacon.sol";

library EnumerableTxRecord {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @dev Query for a nonexistent map key.
     */
    error EnumerableTxRecordNonexistentKey(bytes32 key);

    struct Bytes32ToOmniToLocalRecord {
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 key => ToLocalRecord) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToOmniToLocalRecord storage map,
        bytes32 key,
        ToLocalRecord memory value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true and value if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToOmniToLocalRecord storage map,
        bytes32 key
    ) internal returns (bool, ToLocalRecord memory) {
        ToLocalRecord memory value = map._values[key];
        delete map._values[key];
        return (map._keys.remove(key), value);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToOmniToLocalRecord storage map,
        bytes32 key
    ) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(
        Bytes32ToOmniToLocalRecord storage map
    ) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToOmniToLocalRecord storage map,
        uint256 index
    ) internal view returns (bytes32, ToLocalRecord memory) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToOmniToLocalRecord storage map,
        bytes32 key
    ) internal view returns (bool, ToLocalRecord memory) {
        ToLocalRecord memory value = map._values[key];
        if (value.amount == 0) {
            return (
                contains(map, key),
                ToLocalRecord(bytes(""), bytes(""), 0, 0)
            );
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToOmniToLocalRecord storage map,
        bytes32 key
    ) internal view returns (ToLocalRecord memory) {
        ToLocalRecord memory value = map._values[key];
        if (value.amount == 0 && !contains(map, key)) {
            revert EnumerableTxRecordNonexistentKey(key);
        }
        return value;
    }
}
