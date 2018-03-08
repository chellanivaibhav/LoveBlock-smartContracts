pragma solidity ^0.4.11;

contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
        msg.sender == cooAddress ||
        msg.sender == ceoAddress ||
        msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }


    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}
contract LockBase {

    /*Variables*/
    uint256 public lastPosition;
    /*Mappings*/
    // checks position and returns if its filled or not , returns true if filled else false
    mapping (uint256 => bool) public checkIfFilled;
    // connects lockid and locked lock position
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    // maps the multiplier for each position
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    // connect time and rate for licensing
    mapping (uint64 => uint256) public timeToRateMapping;
    mapping(uint256 => address) public lockIndexToOwner;


    /** Setters */
    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external {}
    function SETcheckIfFilled(uint256 _id,bool _boolean) external {}
    function SETtokenIdToLockedLockPosition(uint256 _id, uint _pos) external {}
    function SETlastPosition(uint256 _pos) external {}
    function incrementLockedLocksCount() external {}
    function decrementLockedLocksCount() external {}
    function incrementLastPosition() external {}

    /** Lock Getters */
    function GETlockStatus(uint256 _id) external view returns (uint256 _lockStatus){}
    /** Lock setters */
    function SETlockstatus(uint256 _id,uint256 lockstatus) external {}

    /** Lock Removers */
    function REMOVElockedLocks(uint256 _pos) external{}
    function DELETEtokenIdToLockedLockPosition(uint256 _id) external {}
}

contract LicenseLock is LockAccessControl {
    LockBase public baseContract;
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));

        baseContract = LockBase(_newBaseAddr);
    }
    /*Events*/
    event LicenseGiven(uint256,uint256,uint64,string,string,address);
    event LicenseRemoved(uint256,uint256);


    /* Constructor */
    function LicenseLock(address baseAddr) {
        baseContract = LockBase(baseAddr);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function licenseLock(
    uint256 _tokenId,
    string _message,
    string _partner,
    uint256 position,
    uint64 time
    ) payable external whenNotPaused
    {
        
        require( msg.value > 0 );
        // check if there exists a non zero rate for given time
        require(baseContract.timeToRateMapping(time) != 0);
        // check if the value given is more than or equal to rate
        require(msg.value >= baseContract.timeToRateMapping(time));
        // check if the owner of lock is msg sender
        require(baseContract.lockIndexToOwner(_tokenId) == msg.sender);
        // check if the position is greater than 0
        require(position >= 0);

        //get lock status from base contract
        var (lock_status) = baseContract.GETlockStatus(_tokenId);
        // checks if the lock is not on chain or on sale
        require(lock_status == 0);
        if(position == 0) {
            require(!baseContract.checkIfFilled(baseContract.lastPosition()+1));

            baseContract.ADDlockedLocks(baseContract.lastPosition()+1,_partner,_message);
            baseContract.incrementLastPosition();
            // fill the position in the array with the lock and generate the new lockedLockId
            uint256 lockedLockId = baseContract.lastPosition();
            // attach the token id with lock position
            baseContract.SETtokenIdToLockedLockPosition(_tokenId,lockedLockId);
            // check the data type
            require(lockedLockId == uint256(uint32(lockedLockId)));
            // mark the position filled
            baseContract.SETcheckIfFilled(lockedLockId,true);
            // fire event
            LicenseGiven(_tokenId,lockedLockId,time,_partner,_message,msg.sender);
        } else {
            // position is coming add it if not filled and update last position if big
            // check if the position is filled
            require(!baseContract.checkIfFilled(position));
            if( position > baseContract.lastPosition() ) {
                // baseContract.lastPosition = position;
                baseContract.SETlastPosition(position);
            }
            // fill the position in the arrray with the lock
            baseContract.ADDlockedLocks(position,_partner,_message);
            // attach the token id with lock position
            baseContract.SETtokenIdToLockedLockPosition(_tokenId,position);
            // mark the position filled
            baseContract.SETcheckIfFilled(position,true);
            LicenseGiven(_tokenId,position,time,_partner,_message,msg.sender);

        }
        // increment lockedLock count
        baseContract.incrementLockedLocksCount();


        // check if the mutiplier exists and transfer accordingly
        if(baseContract.checkMultiplierForPosition(position)!=0) {
            ceoAddress.transfer(baseContract.timeToRateMapping(time)*baseContract.checkMultiplierForPosition(position));
            msg.sender.transfer(msg.value - (baseContract.timeToRateMapping(time)*baseContract.checkMultiplierForPosition(position)));
        } else {
            ceoAddress.transfer(baseContract.timeToRateMapping(time));
            msg.sender.transfer(msg.value - baseContract.timeToRateMapping(time));
        }
        // set lockStatus 1 on chain
        baseContract.SETlockstatus(_tokenId,1);
    }
    function removeLockLicense (uint256 token_id) external onlyCLevel {
        // grabs locked lock position from token id and checks if its filled
        require(baseContract.checkIfFilled(baseContract.tokenIdToLockedLockPosition(token_id)));
        // grabs lock from state and set lock status back to 0
        baseContract.SETlockstatus(token_id,0);
        // event fired
        LicenseRemoved(token_id,baseContract.tokenIdToLockedLockPosition(token_id));
        // deleted lockedLock
        baseContract.REMOVElockedLocks(baseContract.tokenIdToLockedLockPosition(token_id));
        // deleted linking of tokenid and lockedlock
        baseContract.DELETEtokenIdToLockedLockPosition(token_id);
        // decrement lockedLockCount
        baseContract.decrementLockedLocksCount();
        // emptied the space on chain
        baseContract.SETcheckIfFilled(baseContract.tokenIdToLockedLockPosition(token_id),false);
    }
}

