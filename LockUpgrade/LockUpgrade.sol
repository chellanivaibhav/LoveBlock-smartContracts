pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract lockBase{

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


contract LockUpgrade is LockAccessControl{

    /** Events */
    event LockUpgraded (uint lockid, uint256 increaseByValue);

    lockBase baseContract;
    function LockUpgrade(address baseAddr){
        baseContract = lockBase(baseAddr);
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


