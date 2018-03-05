pragma solidity ^0.4.11;
import "./LockAccessControl.sol";



contract LockBuySell is LockAccessControl {

    function LockBuySell() {
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

    function _isOnSale(uint256 _tokenId) external view onlyRWAccess returns(bool) {
        return (tokenIdToSellOrder[_tokenId].status == 1);
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
/*
    issues here : unable to transfer ether in exchange for 721
                do we need a 721 instance here
                making events
                will the contract transfer funds from its account
                will this contract hold money
                we need a way to withdraw money from here



*/