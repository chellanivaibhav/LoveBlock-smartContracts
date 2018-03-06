pragma solidity ^0.4.11;
contract LockAccessControl {
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public lockBuySell;
    address public extraAddress;

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

    /// @dev Access modifier for BuySell implementation functionality
    modifier onlyRWAccess() {
        require(
            msg.sender == lockBuySell ||
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == extraAddress
            );
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

    // for setting LockBuySell implementation contract address
    function setLockBuySell(address _newLockBuySellAddress) external onlyCLevel {
        require(_newLockBuySellAddress != address(0));
        lockBuySell = _newLockBuySellAddress;
    }
    // for setting LockBuySell implementation contract address
    function setExtraAddress(address _newExtraAddress) external onlyCLevel {
        require(_newExtraAddress != address(0));
        extraAddress = _newExtraAddress;
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


contract LockBuySellStorage is LockAccessControl {

    function LockBuySellStorage() {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

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

    function _isOnSale(uint256 _tokenId) external constant onlyRWAccess returns(bool) {
        if(tokenIdToSellOrder[_tokenId].status == 1){
            return true;
        }
        else {
            return false;
        }
    }
    function DELETEsellOrder(uint256 _tokenId) external onlyRWAccess {
        delete tokenIdToSellOrder[_tokenId];
    }

    function ADDsellOrder(uint256 _lock_id,address _sellerAddr,uint256 _sellingPrice,uint256 _status) external onlyRWAccess {
        // TODO: all assertions should be taken care of in the implementation contracts
        SellOrder memory _sellorder = SellOrder({
        seller: _sellerAddr,
        sellingPrice: _sellingPrice,
        lock_id: _lock_id,
        status: _status
        });
        tokenIdToSellOrder[_lock_id] = _sellorder;
    }

    function GETsellOrderAddress(uint256 _lock_id) external onlyRWAccess returns (address) {
        return(tokenIdToSellOrder[_lock_id].seller);
    }

    function GETsellOrderSellingPrice(uint256 _lock_id) external onlyRWAccess returns (uint256) {
        return(tokenIdToSellOrder[_lock_id].sellingPrice);
    }
}