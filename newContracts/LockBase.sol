/// this contract will contain all the storage variables of the whole system , which is mostly locks , this wont change ever
pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract LockBase is LockAccessControl { 
    function LockBase() {
        LockedLock memory firstLockedLock = LockedLock({
            partner : "none",
            message : "none" 
        });
        
        lockedLocks[0] = firstLockedLock;
        checkIfFilled[0] = true;
        lockedLocksCount = 0;

    }
    uint256 public forgingFees =500000000000000000 * 1 wei ;
    function setForgingFee(uint256 _fee) external onlyCLevel {
        forgingFees = _fee;
    }
    event Transfer(address from,address to,uint256 tokenId);
    event LockCreated(address, uint256,string);
    event EventGenerationByForging(uint256[],address);
    event LicenseGiven(uint256,uint256,uint64,string,string,address);
    event LicenseRemoved(uint256,uint256);
    event LimitPlanAdded (uint256,uint256);
    event LimitPlanRemoved(uint256,uint256);
    event LicenseRateTimeAdded(uint256 ,uint256);
    event LicenseRateTimeRemoved(uint256,uint256);
    event LockUpgraded (uint lockid, uint256 increaseByValue);
    // struct of lock , all locks generated would be stored over here
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
    
    /*** STORAGE ***/

    // this array will store all locks , we give id we get lock object , simple and sweet !
    Lock[] public locks;
    uint256 public lockedLocksCount;
    // this array will contain all the locked locks
    mapping(uint256 => LockedLock) public lockedLocks;
    // this mapping will track address of owner with lockid which is basically the index of lock in the above array 
    mapping(uint256 => address) public lockIndexToOwner;
    // this mapping will give us no of locks owned by an address , we will increment this when tranfer of ownership happens
    mapping(address => uint256) ownershipTokenCount;
    // this mapping will track the owner ship approval , will be used for escrowing
    mapping (uint256 => address) public lockIndexToApproved;
    // this will track the amount to increase in no of pic and letter limit with corresponding rate 
    mapping (uint256 => uint256) public limitIncreaseToRate;
    // maps the multiplier for each position 
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    // checks position and returns if its filled or not , returns true if filled else false
    mapping (uint256 => bool) public checkIfFilled;
    // connects lockid and locked lock position 
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    // connect time and rate for licensing 
    mapping (uint64 => uint256) public timeToRateMapping;
    uint256 public lastPosition=0;
    

    /**LICENSING STUFF */
    function addRateAndTime(uint64 time, uint256 rateInWei) onlyCLevel {
        timeToRateMapping[time] = rateInWei;
        LicenseRateTimeAdded(time,timeToRateMapping[time]);
    }

    function removeRateAndTime(uint64 time) onlyCLevel {
        LicenseRateTimeRemoved(time,timeToRateMapping[time]);
        delete timeToRateMapping[time];
    }
    // license lock for given time 
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
        require(timeToRateMapping[time] != 0);
        // check if the value given is more than or equal to rate
        require(msg.value >= timeToRateMapping[time]);
        // check if the owner of lock is msg sender
        require(lockIndexToOwner[_tokenId] == msg.sender);
        // check if the position is greater than 0
        require(position >= 0);
        // make the LockedLock object
        LockedLock memory _lockedLock = LockedLock({
            partner : _partner,
            message : _message 
        }); 
        Lock storage lockToBeLicensed = locks[_tokenId];
        // checks if the lock is not on chain or on sale 
        require(lockToBeLicensed.lockStatus == 0);
        if(position == 0) {
            lockedLocks[lastPosition+1] = _lockedLock;
            lastPosition++;
            // fill the position in the array with the lock and generate the new lockedLockId
            uint256 lockedLockId = lastPosition;
            // attach the token id with lock position
            tokenIdToLockedLockPosition[_tokenId]=lockedLockId;
            // check the data type
            require(lockedLockId == uint256(uint32(lockedLockId)));
            // mark the position filled
            checkIfFilled[lockedLockId]=true;
        } else {
            // position is coming add it if not filled and update last position if big
            // check if the position is filled 
            require(!checkIfFilled[position]);
            if(position > lastPosition ) {
                lastPosition = position;
            }
            // fill the position in the arrray with the lock
            lockedLocks[position] = _lockedLock;
            // attach the token id with lock position
            tokenIdToLockedLockPosition[_tokenId] = position;
            // mark the position filled
            checkIfFilled[position] = true;
            
        }
        // increment lockedLock count
        lockedLocksCount++;
        
        
        // check if the mutiplier exists and transfer accordingly
        if(checkMultiplierForPosition[position]!=0) {
                ceoAddress.transfer(timeToRateMapping[time]*checkMultiplierForPosition[position]); 
                msg.sender.transfer(msg.value - timeToRateMapping[time]);
            } else {
                ceoAddress.transfer(timeToRateMapping[time]); 
                msg.sender.transfer(msg.value - timeToRateMapping[time]);
        }
        // change the lock status to on chain 
        lockToBeLicensed.lockStatus = 1;
        LicenseGiven(_tokenId,position,time,_partner,_message,msg.sender);
    }
    function removeLockLicense (uint256 token_id) external onlyCLevel {       
            // grabs locked lock position from token id and checks if its filled
            require(checkIfFilled[tokenIdToLockedLockPosition[token_id]]);
            // grabs lock from state 
            Lock storage lockToBeRemoved = locks[token_id];
            // changes the status of lock to default
            lockToBeRemoved.lockStatus=0;

            // event fired
            LicenseRemoved(token_id,tokenIdToLockedLockPosition[token_id]);
            // deleted lockedLock
            delete lockedLocks[tokenIdToLockedLockPosition[token_id]];
            // deleted linking of tokenid and lockedlock
            delete tokenIdToLockedLockPosition[token_id];
            // decrement lockedLockCount
            lockedLocksCount--;

            // emptied the space on chain
            checkIfFilled[tokenIdToLockedLockPosition[token_id]] = false;
    }


    /**  Upgrade Lock  */
    function upgradeLock(uint256 lockId,uint256 increaseByValue) external payable whenNotPaused {
        // check if the person calling is the owner of lock
        require(lockIndexToOwner[lockId]==msg.sender);
        // get lock
        Lock storage lockToBeUpgraded = locks[lockId];
        // check if the plan exists
        require(limitIncreaseToRate[increaseByValue]!=0);
        // check of the value is more than that has to be transferred 
        require(msg.value >= limitIncreaseToRate[increaseByValue]);
        // transfer the rate to ceoAddress
        ceoAddress.transfer(limitIncreaseToRate[increaseByValue]);
        require( msg.value > 0 );
        // trasfer the remainder to sender
        msg.sender.transfer(msg.value - limitIncreaseToRate[increaseByValue]);
        // increase the values by given amount
        lockToBeUpgraded.lettersLimit = lockToBeUpgraded.lettersLimit+increaseByValue;
        lockToBeUpgraded.picsLimit = lockToBeUpgraded.picsLimit+increaseByValue;
        LockUpgraded(lockId,increaseByValue);
    }
    // function for adding the plans to upgrade account
    function addLimitAndRate(uint256 limit, uint256 rate) onlyCLevel {
        // limit has to be multiple of 5
        require((limit%5)==0);
        // increase the limit of lock by given number when give with the given int 
        limitIncreaseToRate[limit] = rate;
        LimitPlanAdded(limit,rate);
    }
    // function for removing upgrade plans 
    // params : limit
    function removeLimitAndRate(uint256 limit) onlyCLevel {
        //check if plan to be deleted exists
        require(limitIncreaseToRate[limit]!=uint256(0));
        // fire event 
        LimitPlanRemoved(limit,limitIncreaseToRate[limit]);
        // remove from mapping
        delete limitIncreaseToRate[limit];
    }

    //TODO
    //SaleClockAuction public saleAuction;
    function isOwnerOf(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return lockIndexToOwner[_tokenId] == _claimant;
    }


    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        // transfer ownership
        lockIndexToOwner[_tokenId] = _to;
        // When creating new locks _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete lockIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }


    /** Lock Generation  */
    // function to generate locks , to be used by c level 
    function _generationCEO (
        string _blueprint,
        uint256[] _parents,
        uint256 _lettersLimit,
        uint256 _picsLimit
    ) onlyCLevel returns (uint256)
    {
        Lock memory _lock = Lock(
            {
            lockBlueprint:_blueprint,
            creationTime: uint64(now),
            parentArray:_parents,
            lockStatus: 0,
            lettersLimit: _lettersLimit,
            picsLimit : _picsLimit
        });

        uint256 newLockId = locks.push(_lock) - 1;
        require(newLockId == uint256(uint32(newLockId)));
        // transfers newly generated locks to ceoaddress
        _transfer(0,ceoAddress,newLockId);
       
       // fire event
        LockCreated( ceoAddress,newLockId,_blueprint);

        return newLockId;

    }
    // callback function to be used by us to send the whole lock data and creating lock 
    function __callback(string _blueprint,address owner, uint256[] _parents,uint256 _letterLimit,uint256 _picLimit) onlyCallBackAddress returns (uint256) { 
        
        Lock memory _lock = Lock({
            lockBlueprint:_blueprint,
            creationTime: uint64(now),
            parentArray:_parents,
            lockStatus: 0,
            lettersLimit: _letterLimit,
            picsLimit : _picLimit
        });

        uint256 newLockId = locks.push(_lock) - 1;
        require(newLockId == uint256(uint32(newLockId)));
        // emit generation event 
        // execute _transferfunction 
        // transefers newly generated locks to owner address 
        _transfer(0, owner, newLockId);
        LockCreated(owner,newLockId,_blueprint);

        return newLockId;
        
    }
    // function to be called by user for generating new locks by forging
    function _generationByForging(uint256[] _parents) public payable whenNotPaused {
        //oraclise call
        // add cut here 
        require(_parents.length <= 3);
        for ( uint256 i = 0 ; i < _parents.length ; i++ ) {
            require(isOwnerOf(msg.sender,_parents[i]));
        }
        require(msg.value > forgingFees);
        ceoAddress.transfer(forgingFees);
        msg.sender.transfer(msg.value - forgingFees);

        EventGenerationByForging(_parents,msg.sender);
    }

    
    // adds multiplier for specific location
    function addMultiplierForPosition(uint256 pos,uint256 mul) external onlyCLevel {
        // to put or not to put 
        require(mul >= 1);
        checkMultiplierForPosition[pos] = mul;
    }
    function removeMultiplierForPosition (uint256 pos) external onlyCLevel { 
        // checks if exists
        require(checkMultiplierForPosition[pos]!=0);
        // removes
        delete checkMultiplierForPosition[pos];
    }
    function getParentsOfLock(uint256 lockId) constant external returns (uint256[]) { 
        Lock storage referencedLock = locks[lockId];
        return referencedLock.parentArray;
    }
    


}