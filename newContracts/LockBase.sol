/// this contract will contain all the storage variables of the whole system , which is mostly locks , this wont change ever
pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract LockBase is LockAccessControl { 

    // events to be generated 
    // transfer 
    // created new lock either from forging or from creation by ceo
    event Transfer(address from,address to,uint256 tokenId);
    event GeneratedLock(address owner, uint256 lockId, Lock lock);


    // struct of lock , all locks generated would be stored over here
    struct Lock {

        uint256 lockBlueprint;
        uint64 creationTime;
        //parent id array 
        uint[] parentArray;
        // status means onrent, for sale , locked , unlocked and more 
        // for now lets assume , 0 is the default , unlocked,unrented,notonsale
        // 2 means on sale 
        uint8 lockStatus;
        // assume 
        uint256 lettersLimit;
        uint256 picsLimit;
    }
    /*** STORAGE ***/

    // this array will store all locks , we give id we get lock object , simple and sweet !
    Lock[] locks;
    // this mapping will track address of owner with lockid which is basically the index of lock in the above array 
    mapping(uint256 => address) public lockIndexToOwner;
    // this mapping will give us no of locks owned by an address , we will increment this when tranfer of ownership happens
    mapping(address => uint256) ownershipTokenCount;
    // this mapping will track the owner ship approval , will be used for escrowing
    mapping (uint256 => address) public lockIndexToApproved;

    //TODO
    //SaleClockAuction public saleAuction;

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
    function _generationCEO (
        uint256 _blueprint,
        uint256[] _parents,
        uint _lettersLimit,
        uint _picsLimit
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
        // emit generation event 
        // execute _transferfunction 
        // transefers newly generated locks to ceoaddress
        _transfer(0, ceoAddress, newLockId);
        GeneratedLock(ceoAddress,newLockId,_lock);
        return newLockId;

    }
    function _generationByForging(uint256[] _parents) {
        //oraclise call
    }
    // put functions for generation of gen0 locks 
    // put function for generation of forged locks


}

// things to sort in this contract 
// adding of variables of sibling contracts (39)
// adding of events or transfer and generation 
// creation of gen0 and forged locks functions 

//REST IS DONE , i guess 