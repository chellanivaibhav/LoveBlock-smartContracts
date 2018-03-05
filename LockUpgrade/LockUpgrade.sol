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

    /*strcts*/
    struct Lock {
    string lockBlueprint;
    uint64 creationTime;
    //parent id array
    uint256[] parentArray;
    // we wont be able to store the incoming info directly
    //mapping (uint256 => uint256) parentArray;
    // status means onrent, for sale , locked , unlocked and more
    // for now lets assume , 0 is the default , unlocked,unrented,notonsale
    // 2 means on sale
    // 1 means on chain
    uint256 lockStatus;
    uint256 lettersLimit;
    uint256 picsLimit;
    }

    struct LockedLock {
    string message;
    string partner;
    }

    // this array will store all locks , we give id we get lock object , simple and sweet !
    Lock[] public locks;

    /*Variables*/
    uint256 public lockedLocksCount;
    uint256 public lastPosition;

    /*Mappings*/
    // this array will contain all the locked locks
    mapping(uint256 => LockedLock) public lockedLocks;
    // checks position and returns if its filled or not , returns true if filled else false
    mapping (uint256 => bool) public checkIfFilled;
    // this will track the amount to increase in no of pic and letter limit with corresponding rate
    mapping (uint256 => uint256) public limitIncreaseToRate;
    // connects lockid and locked lock position
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    // maps the multiplier for each position
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    // connect time and rate for licensing
    mapping (uint64 => uint256) public timeToRateMapping;
    mapping(uint256 => address) public lockIndexToOwner;


    /** Setters */
    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external {}
    function SETlockIndexToOwner(uint256 _lockId, address _address) external {}
    function SETownershipTokenCount(address _addr, uint _count) external  {}
    function SETlockIndexToApproved(uint256 _id,address _addr) external  {}
    function SETlimitIncreaseToRate(uint256 _id, uint _increment) external {}
    function SETcheckMultiplierForPosition(uint256 _id,uint _multiplier) external {}
    function SETcheckIfFilled(uint256 _id,bool _boolean) external {}
    function SETtokenIdToLockedLockPosition(uint256 _id, uint _pos) external {}
    function SETtimeToRateMapping(uint64 _time, uint256 _rate) external {}
    function SETlastPosition(uint256 _pos) external {}
    function incrementLockedLocksCount() external {}
    function decrementLockedLocksCount() external {}
    function incrementLastPosition() external {}

    /** Lock Getters */
    function get_Lock_blueprint(uint256 _id) external view returns (string _blueprint){}
    function get_Lock_creationTime(uint256 _id) external view returns (uint64 _creationtime){}
    function get_Lock_parents(uint256 _id) external view returns (uint256[] _parentIds){}
    function GETlockStatus(uint256 _id) external view returns (uint256 _lockStatus){}
    function GETlockletterLim(uint256 _id) external view returns (uint256 _lettersLimit){}
    function GETlockpicsLim(uint256 _id) external view returns (uint256 _picslimit){}

    /** Lock setters */
    function SETlockstatus(uint256 _id,uint256 lockstatus) external {}
    function SETlockletterLim(uint256 _id, uint256 _letterLim) external {}
    function SETlockpicLim(uint256 _id,uint256 _picLim) external {}

    /** Lock Removers */
    function REMOVElockedLocks(uint256 _pos) external{}
    function DELETEtokenIdToLockedLockPosition(uint256 _id) external {}
}


contract LockUpgrade is LockAccessControl {

    /** Events */
    event LockUpgraded (uint lockid, uint256 increaseByValue);

    LockBase baseContract;
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));

        baseContract = LockBase(_newBaseAddr);
    }
    function LockUpgrade(address baseAddr) {
        baseContract = LockBase(baseAddr);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /**  Upgrade Lock  */
    function upgradeLock(uint256 lockId,uint256 increaseByValue) external payable whenNotPaused {
        // check if the person calling is the owner of lock
        require(baseContract.lockIndexToOwner(lockId)==msg.sender);
        // get lock
        // Lock storage lockToBeUpgraded = locks[lockId];
        uint256 lockLetterLim = baseContract.GETlockletterLim(lockId);
        uint256 lockPicLim = baseContract.GETlockpicsLim(lockId);
        // check if the plan exists
        require(baseContract.limitIncreaseToRate(increaseByValue)!=0);
        // check of the value is more than that has to be transferred
        require(msg.value >= baseContract.limitIncreaseToRate(increaseByValue));
        // transfer the rate to ceoAddress
        ceoAddress.transfer(baseContract.limitIncreaseToRate(increaseByValue));
        // trasfer the remainder to sender
        msg.sender.transfer(msg.value - baseContract.limitIncreaseToRate(increaseByValue));
        // increase the values by given amount
        baseContract.SETlockletterLim(lockId,lockLetterLim+increaseByValue);
        baseContract.SETlockpicLim(lockId,lockPicLim+increaseByValue);
        // fire event
        LockUpgraded(lockId,increaseByValue);
    }
}


