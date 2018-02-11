pragma solidity ^0.4.11;
import "./LockOwnership.sol";


// this is how it will work
// call 
//
//
//
//
//
//

contract LockBuySell is LockOwnership {
    struct SellOrder {
        address seller ;
        uint256 sellingPrice;
        // status can be 0=inactive or cancelled , 1 = posted and active , 2= posted and fulfilled
        uint8 status;
        uint lock_id;
    }
    /*** Storage**/
    mapping(uint256=>SellOrder) public tokenIdToSellOrder;
    // mapping to get the no of sell orders per address 
    mapping(address => uint256) sellOrderCount;
    function _isOnSale(uint256 _tokenId) internal view returns(bool) {
        return (tokenIdToSellOrder[_tokenId].status == 1);
    }
    function _removeSellOrder(uint256 _tokenId) internal {
        delete tokenIdToSellOrder[_tokenId];
    }
    function _approveOwner (uint lock_id) external {
        this.approve(this,lock_id);
    }

    // fetch the lock , check owner is the msg.sender , change lockstatus to onsale 
    // will be called by owner of lock
    // check if or front end will call this or contract 
    function createSellOrder(uint256 price, uint256 _lock_id) external {
        // add require statements to validate input 
        // checks if the owner is msg.sender , only the owner can put sell order 
        require(_owns(msg.sender, _lock_id));

        // TODO check if lock with this tokenid exists
        Lock storage sellingLock = locks[_lock_id];

        //TODO is this needed 
        sellingLock.lockStatus = 2;
        //issue solved by making it external 
        _approveOwner(_lock_id);
        SellOrder memory _sellorder = SellOrder({
            seller: msg.sender,
            sellingPrice: price,
            lock_id: _lock_id,
            status: 1
        });
        
        tokenIdToSellOrder[_lock_id] = _sellorder;
        //checks overflow
        //emit sell event
        
    }
    // checks if the sender is owner of lock , checks if the lock is on sale 
    // what happens if the token id which is provide is not on sale , i guess it wil recieve status as 0
    function cancelSellOrder(uint256 token_id) {
        require(_owns(msg.sender,token_id));
        require(_isOnSale(token_id));
        _removeSellOrder(token_id);
    }
    function buySellOrder(uint256 token_id) external payable  {
        tokenIdToSellOrder[token_id];
        require(_isOnSale(token_id));

        // transfer ownership to caller 
        // msg.value from line 85 
        // to be countinued from here
        address seller_address = tokenIdToSellOrder[token_id].seller;  
        uint256 selling_price = tokenIdToSellOrder[token_id].sellingPrice;
        require(selling_price <= msg.value);
        _removeSellOrder(token_id);
        seller_address.transfer(selling_price);
        this.transferFrom(seller_address, msg.sender, token_id);


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