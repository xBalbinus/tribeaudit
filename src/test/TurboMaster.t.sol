// SPDX-License-Identifier: AGPL-3.0-only
import "./TurboMaster.sol";


contract createSafeTest is TurboMaster {

    // add the property test
    function echidna_createSafe() view public returns(bool){
        return safes.length <= 10000;
    }   


}

