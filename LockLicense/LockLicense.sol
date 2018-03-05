pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract LockBase {

    /*structs*/
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
contract LicenseLock is LockAccessControl {
    LockBase baseContract;

    /*Events*/
    event LicenseGiven(uint256,uint256,uint64,string,string,address);
    event LicenseRemoved(uint256,uint256);

    /*Structs*/
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

    /* Constructor */
    function license_Lock(address baseAddr) {
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
            msg.sender.transfer(msg.value - baseContract.timeToRateMapping(time));
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
