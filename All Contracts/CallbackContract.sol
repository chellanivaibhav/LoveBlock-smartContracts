pragma solidity ^0.4.11;

contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public callBackAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCallBack() {
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
    
    function setCallBack(address _newCallBackAddress) external onlyCLevel {
        require(_newCallBackAddress != address(0));

        callBackAddress = _newCallBackAddress;
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
    function throwLockCreatedEvent(address owner,uint256 newLockId,string _blueprint) constant {}
    function _transfer(address _from, address _to, uint256 _tokenId) external {}
    uint256 public maxNumberOfParents;
    mapping(uint256 => address) public lockIndexToOwner;
    function SETlockParent(uint256[] _parents,uint256 _id) external {}
    function SETlockstatus(uint256 _id,uint lockstatus) external {}
    /* Lock Letter Limit Setter */
    function SETlockletterLim(uint256 _id, uint _letterLim) external {}
    /* Lock Pics Limit Setter */
    function SETlockpicLim(uint256 _id,uint _picLim) external {}
    function SETblueprint(string _blueprint, uint256 _id) external  {}

}
contract CallbackContract is LockAccessControl {
    
    LockBase public baseContract;
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));
        baseContract = LockBase(_newBaseAddr);
    }
    function LockCreateByForging(address baseAddr) {
        baseContract = LockBase(baseAddr);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    
    
    // callback function to be used by us to send the whole lock data and creating lock
    function __callback(string _blueprint,address owner, uint256[] _parents,uint256 _letterLimit,uint256 _picLimit,uint256 _lockId) onlyCallBack whenNotPaused returns(uint256)  {
        require(_parents.length <= baseContract.maxNumberOfParents());
        for ( uint256 i = 0 ; i < _parents.length ; i++ ) {
            require(baseContract.lockIndexToOwner(_parents[i])==owner);
        }
        baseContract.SETblueprint(_blueprint,_lockId);
        baseContract.SETlockpicLim(_lockId,_picLimit);
        baseContract.SETlockletterLim(_lockId,_letterLimit);
        baseContract.SETlockstatus(_lockId,0);
        baseContract.SETlockParent(_parents,_lockId);
        
        // transefers newly generated locks to owner address
        baseContract._transfer(0, owner, _lockId);
        baseContract.throwLockCreatedEvent(owner,_lockId,_blueprint);
        return 0;
    }
}
