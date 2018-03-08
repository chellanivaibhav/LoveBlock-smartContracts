/// this contract will contain all the storage variables of the whole system , which is mostly locks , this wont change ever
pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract LockBase is LockAccessControl {
    function LockBase() {
        //Initialises 0th position(also 0 lockID) of locked locks.
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
    // events to be generated
    // transfer
    // created new lock either from forging or from creation by ceo
    event Transfer(address from,address to,uint256 tokenId);
    event LockCreated(address, uint256,string);
    event EventGenerationByForging(uint256[],address);
    event LimitPlanAdded (uint256,uint256);
    event LimitPlanRemoved(uint256,uint256);
    event LicenseRateTimeAdded(uint256 ,uint256);
    event LicenseRateTimeRemoved(uint256,uint256);

    // struct of lock , all locks generated would be stored over here
    struct Lock {
    string lockBlueprint;
    uint64 creationTime;
    //parent id array
    uint256[] parentArray;
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
    // used in generation by forging 
    uint256 public maxNumberOfParents = 3;
    /*LICENSING STUFF */
    function addRateAndTime(uint64 time, uint256 rateInWei) onlyCLevel {
        timeToRateMapping[time] = rateInWei;
        LicenseRateTimeAdded(time,timeToRateMapping[time]);
    }

    function removeRateAndTime(uint64 time) onlyCLevel {
        LicenseRateTimeRemoved(time,timeToRateMapping[time]);
        delete timeToRateMapping[time];
    }

    function AddMaxNumberOfParents(uint numberOfParents) onlyCLevel {
        maxNumberOfParents=numberOfParents;
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

    function _transfer(address _from, address _to, uint256 _tokenId) external RWAccess {
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
        this._transfer(0,ceoAddress,newLockId);

        // fire event
        LockCreated( ceoAddress,newLockId,_blueprint);

        return newLockId;

    }
    // callback function to be used by us to send the whole lock data and creating lock
    function __callback(string _blueprint,address owner, uint256[] _parents,uint256 _letterLimit,uint256 _picLimit) onlyCallBack returns (uint256) {

        require(_parents.length <= maxNumberOfParents);
        for ( uint256 i = 0 ; i < _parents.length ; i++ ) {
            require(lockIndexToOwner[_parents[i]]==owner);
        }

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
        // transefers newly generated locks to owner address
        this._transfer(0, owner, newLockId);
        LockCreated( owner,newLockId,_blueprint);

        return newLockId;

    }
    // function to be called by user for generating new locks by forging
    function _generationByForging(uint256[] _parents) public payable whenNotPaused {
        //oraclise call
        require(_parents.length <= maxNumberOfParents);
        for ( uint256 i = 0 ; i < _parents.length ; i++ ) {
            require(lockIndexToOwner[_parents[i]]==msg.sender);
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

    /* Locked lock adder */
    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external RWAccess {
        LockedLock memory _lockedLock = LockedLock({
        message: _message,
        partner: _partner
        });

        lockedLocks[_lockId] = _lockedLock;
    }
    /* Mapping Setter */
    function SETlockIndexToOwner(uint256 _lockId, address _address) external RWAccess{
        lockIndexToOwner[_lockId] = _address;
    }
    /* Mapping Setter */
    function SETownershipTokenCount(address _addr, uint256 _count) external RWAccess{
        ownershipTokenCount[_addr] = _count;
    }
    /* Mapping Setter */
    function SETlockIndexToApproved(uint256 _id,address _addr) external RWAccess{
        lockIndexToApproved[_id] = _addr;
    }
    /* Mapping Setter */
    function SETlimitIncreaseToRate(uint256 _id, uint _increment) external RWAccess{
        limitIncreaseToRate[_id] = _increment;
    }
    /* Mapping Setter */
    function SETcheckMultiplierForPosition(uint256 _id,uint _multiplier) external RWAccess{
        checkMultiplierForPosition[_id] = _multiplier;
    }
    /* Mapping Setter */
    function SETcheckIfFilled(uint256 _id,bool _boolean) external RWAccess{
        checkIfFilled[_id] = _boolean;
    }
    /* Mapping Setter */
    function SETtokenIdToLockedLockPosition(uint256 _id, uint _pos) external RWAccess{
        tokenIdToLockedLockPosition[_id] = _pos;
    }
    /* Mapping Setter */
    function SETtimeToRateMapping(uint64 _time, uint _rate) external RWAccess{
        timeToRateMapping[_time] = _rate;
    }
    /* Lock Getter */
    function GETlockblueprint(uint _id) external view RWAccess returns (string _blueprint){
        return(locks[_id].lockBlueprint);
    }
    // /* Lock Getter */
    function GETlockcreationTime(uint _id) external view RWAccess returns (uint64 _creationtime){
        return(locks[_id].creationTime);
    }
    // /* Lock Getter */
    function GETlockparents(uint _id) external view RWAccess returns (uint[] _parentIds){
        return(locks[_id].parentArray);
    }
    /* Lock Getter */
    function GETlockStatus(uint256 _id) external view RWAccess returns(uint256){
        return(locks[_id].lockStatus);
    }
    /* Lock Getter */
    function GETlockletterLim(uint256 _id) external view RWAccess returns (uint256 _lettersLimit) {
        return(locks[_id].lettersLimit);
    }
    /* Lock Getter */
    function GETlockpicsLim(uint256 _id) external view RWAccess returns (uint256 _picslimit) {
        // Lock memory l = locks[_id];
        return(locks[_id].picsLimit);
    }

    /* Lock Status Setter */
    function SETlockstatus(uint256 _id,uint lockstatus) external RWAccess{
        Lock storage l = locks[_id];
        l.lockStatus = lockstatus;
    }
    /* Lock Letter Limit Setter */
    function SETlockletterLim(uint256 _id, uint _letterLim) external RWAccess{
        Lock storage l = locks[_id];
        l.lettersLimit = _letterLim;
    }
    /* Lock Pics Limit Setter */
    function SETlockpicLim(uint256 _id,uint _picLim) external RWAccess{
        Lock storage l = locks[_id];
        l.picsLimit = _picLim;
    }
    /* Mapping Remover */
    function DELETEtokenIdToLockedLockPosition(uint256 _id) external RWAccess{
        delete tokenIdToLockedLockPosition[_id];
    }
    /* Locked lock Remover */
    function REMOVElockedLocks(uint256 _pos) external RWAccess {
        delete lockedLocks[_pos];
    }
    /* Increments locked locks count */
    function incrementLockedLocksCount() external RWAccess {
        lockedLocksCount++;
    }
    /* Decrements locked locks count */
    function decrementLockedLocksCount() external RWAccess {
        lockedLocksCount--;
    }
    /* Increments last position */
    function incrementLastPosition() external RWAccess {
        lastPosition++;
    }
    /* Last Position Setter */
    function SETlastPosition(uint _pos) external RWAccess {
        lastPosition = _pos;
    }
    function getParentsOfLock(uint256 lockId) constant external returns (uint256[]) {
        Lock storage referencedLock = locks[lockId];
        return referencedLock.parentArray;
    }
}