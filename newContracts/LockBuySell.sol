pragma solidity ^0.4.11;
import "./LockOwnership.sol";


// this is how it will work
// call 

contract LockBuySell is LockOwnership {
    /** events */
    event SellOrderCreated(uint256,uint256,address);
    event SellOrderCancelled( SellOrder sellorder, uint256 id);
    event SellOrderFulFilled(uint256,uint256,address,address);
    


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
        SellOrderCancelled(tokenIdToSellOrder[_tokenId],_tokenId);
        delete tokenIdToSellOrder[_tokenId];
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

        _approve(_lock_id,this);
        SellOrder memory _sellorder = SellOrder({
            seller: msg.sender,
            sellingPrice: price,
            lock_id: _lock_id,
            status: 1
        });
        
        tokenIdToSellOrder[_lock_id] = _sellorder;
        //checks overflow
        //emit sell event
        SellOrderCreated(price,_lock_id,msg.sender);
        
    }
    // checks if the sender is owner of lock , checks if the lock is on sale 
    function cancelSellOrder(uint256 token_id) {
        // check if the msg.sender owns the lock
        require(_owns(msg.sender,token_id));
        //check if the lock is on sale
        require(_isOnSale(token_id));
        // remove the lock sell order
        _removeSellOrder(token_id);
    }
    function buySellOrder(uint256 token_id, uint256 amount ) external payable {
        // check if the given lock is on sale
        require(_isOnSale(token_id));

        // change status of lock to defaut
        Lock storage sellingLock = locks[token_id];
        sellingLock.lockStatus = 0;
        
        // fetch seller and price before deleting
        address seller_address = tokenIdToSellOrder[token_id].seller;  
        uint256 selling_price = tokenIdToSellOrder[token_id].sellingPrice;
        require(selling_price <= amount);

        // remove sell order to prevent reentrancy attack
        _removeSellOrder(token_id);

        // TODO if the  buyer sends more money then needed return back
        //uint256 remainder = amount-selling_price;
        
        // not working 
        //seller_address.transfer(selling_price);
        
        require(_approvedFor(this, token_id));
        require(_owns(seller_address, token_id)); 

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(seller_address, msg.sender ,token_id);        
        SellOrderFulFilled(token_id,selling_price,seller_address,msg.sender);

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