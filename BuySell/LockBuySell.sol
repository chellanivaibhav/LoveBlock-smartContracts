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

    /// @dev Assigns a new address for base contract. Just in case!
    /// @param _newBaseAddr The address of the new base contract
    

    

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
    // connects lockid and locked lock position
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    // maps the multiplier for each position
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    // connect time and rate for licensing
    mapping (uint64 => uint256) public timeToRateMapping;
    mapping(uint256 => address) public lockIndexToOwner;
    

    /** Setters */
    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external { }
    function SETlockIndexToOwner(uint256 _lockId, address _address) external { }
    function SETownershipTokenCount(address _addr, uint _count) external { }
    function SETlockIndexToApproved(uint256 _id,address _addr) external { }
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

    /** Lock ownership */
    function _approve(uint256 _tokenId, address _approved) external {}
    function _owns(address _claimant, uint256 _tokenId) view external returns (bool) {}
    function _approvedFor(address _claimant, uint256 _tokenId) view external returns (bool) {}
    function _transfer(address _from, address _to, uint256 _tokenId) external {}
}

/** BuySell interface **/

contract BuySellStorage {

    struct SellOrder {
    address seller ;
    uint256 sellingPrice;
    // status can be 0=inactive or cancelled , 1 = posted and active , 2= posted and fulfilled
    uint status;
    uint lock_id;
    }

    /*** Storage**/
    mapping(uint256 => SellOrder) public tokenIdToSellOrder;
    // mapping to get the no of sell orders per address
    mapping(address => uint256) sellOrderCount;

    function _isOnSale(uint256 _tokenId) external view returns(bool) {}
    function DELETEsellOrder(uint256 _tokenId) external {}
    function ADDsellOrder(uint _lock_id,address _sellerAddr,uint _sellingPrice,uint _status) external {}
    function GETsellOrderAddress(uint _lock_id) external returns (address) {}
    function GETsellOrderSellingPrice(uint _lock_id) external returns (uint) {}
} 

contract LockBuySell is LockAccessControl {
    BuySellStorage buysellstorage;
    LockBase baseContract;
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));
        baseContract = LockBase(_newBaseAddr);
    }
    /// @dev Assigns a new address for buysell storage contract. Just in case!
    /// @param _newBuySellStorage The address of the new base contract
    function setBuySellStorageAddr(address _newBuySellStorage) external onlyCLevel {
        require(_newBuySellStorage != address(0));

        buysellstorage = BuySellStorage(_newBuySellStorage);
    }
    uint256 public cut=3;
    function setCut(uint256 _cut) external onlyCLevel {
        cut = _cut;
    }

    function LockBuySell(address baseLockAddr, address _buysellstorageAddr) {
        baseContract = LockBase(baseLockAddr);
        buysellstorage = BuySellStorage(_buysellstorageAddr);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /** events */
    event SellOrderCreated(uint256,uint256,address);
    event SellOrderCancelled(uint256);
    event SellOrderFulFilled(uint256,uint256,address,address);

    // fetch the lock , check owner is the msg.sender , change lockstatus to onsale
    // will be called by owner of lock
    // check if or front end will call this or contract
    function createSellOrder(uint256 price, uint256 _lock_id) payable whenNotPaused {
        // add require statements to validate input
        // checks if the owner is msg.sender , only the owner can put sell order
        require(baseContract._owns(msg.sender, _lock_id));
        uint256 value= price * 1 wei;
        require(msg.value >= (cut*value)/100);
        ceoAddress.transfer((cut*value)/100);
        msg.sender.transfer(msg.value - (cut*value)/100);
        // TODO check if lock with this tokenid exists
        // Lock storage sellingLock = locks[_lock_id];
        uint256 lock_status = baseContract.GETlockStatus(_lock_id);
        require(lock_status == 0);
        //TODO is this needed
        // sets lock status to 2
        baseContract.SETlockstatus(_lock_id,2);

        baseContract._approve(_lock_id,this);
        // creates sellOrder and sets tokenIdToSellOrder
        buysellstorage.ADDsellOrder(_lock_id,msg.sender,value,1);
        //checks overflow
        //emit sell event
        SellOrderCreated(_lock_id,value,msg.sender);
    }

    // checks if the sender is owner of lock , checks if the lock is on sale
    function cancelSellOrder(uint256 token_id) whenNotPaused {
        // check if the msg.sender owns the lock
        require(baseContract._owns(msg.sender,token_id));
        //check if the lock is on sale
        require(buysellstorage._isOnSale(token_id));
        // sets lockStatus back to 0
        baseContract.SETlockstatus(token_id,0);
        // remove the lock sell order
        buysellstorage.DELETEsellOrder(token_id);
        // fire event
        SellOrderCancelled(token_id);
    }

    function buySellOrder(uint256 token_id ) payable whenNotPaused{
        // check if the given lock is on sale
        require(buysellstorage._isOnSale(token_id));
        // sets lockStatus back to 0
        baseContract.SETlockstatus(token_id,0);

        // fetch seller and price before deleting
        address seller_address = buysellstorage.GETsellOrderAddress(token_id);
        uint256 selling_price = buysellstorage.GETsellOrderSellingPrice(token_id) * 1 wei;
        require(selling_price + (selling_price*cut)/100 <= msg.value);

        ceoAddress.transfer((selling_price*cut)/100);
        seller_address.transfer(selling_price);
        msg.sender.transfer(msg.value - (selling_price + (selling_price*3)/100));
        // delete sell order to prevent reentrancy attack
        buysellstorage.DELETEsellOrder(token_id);

        require(baseContract._approvedFor(this, token_id));
        require(baseContract._owns(seller_address, token_id));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        baseContract._transfer(seller_address, msg.sender ,token_id);
        SellOrderFulFilled(token_id,selling_price,seller_address,msg.sender);
    }
}