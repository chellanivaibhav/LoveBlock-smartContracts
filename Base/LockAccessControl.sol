/// this contract will contain mostly the address of ceo , cfo , cto and pausing and unpausing of contract


pragma solidity ^0.4.11;
contract LockAccessControl {
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public callbackAddress;
    address public lockUpgradeAddress;
    address public lockBuySellAddress;
    address public lockLicenseAddress;


    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCallBack() {
        require(msg.sender == callbackAddress);
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

    /// @dev Access modifier for LockBuySell contract functionality
    modifier onlyBuySell() {
        require(msg.sender == lockBuySellAddress);
        _;
    }

    /// @dev Access modifier for LockUpgrade contract functionality
    modifier onlyUpgrade() {
        require(msg.sender == lockUpgradeAddress);
        _;
    }

    /// @dev Access modifier for LockLicense contract functionality
    modifier onlyLicense() {
        require(msg.sender == lockLicenseAddress);
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

    modifier RWAccess() {
        require(
        msg.sender == lockLicenseAddress ||
        msg.sender == lockUpgradeAddress ||
        msg.sender == lockBuySellAddress ||
        // just in case.
        msg.sender == ceoAddress ||
        msg.sender == address(this)
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new CEO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    
    function setCallBackAddress(address _newCallBackAddress) external onlyCLevel {
         require(_newCallBackAddress != address(0));
         callbackAddress = _newCallBackAddress;
     }

    /// @dev Assigns a new address for LockUpgrade contract. Only available to the current CEO.
    /// @param _newLockUpgradeAddr The address of the new LockUpgrade contract
    function setLockUpgradeAddress(address _newLockUpgradeAddr) external onlyCEO {
        require(_newLockUpgradeAddr != address(0));

        lockUpgradeAddress = _newLockUpgradeAddr;
    }

    /// @dev Assigns a new address for LockBuySell contract. Only available to the current CEO.
    /// @param _newLockBuySellAddr The address of the new LockBuySell contract
    function setLockBuySellAddress(address _newLockBuySellAddr) external onlyCEO {
        require(_newLockBuySellAddr != address(0));

        lockBuySellAddress = _newLockBuySellAddr;
    }

    /// @dev Assigns a new address for LockLicense contract. Only available to the current CEO.
    /// @param _newLockLicenseAddr The address of the new LockLicense contract
    function setLockLicenseAddress(address _newLockLicenseAddr) external onlyCEO {
        require(_newLockLicenseAddr != address(0));

        lockLicenseAddress = _newLockLicenseAddr;
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

// things to be done here
// everything seems sorted over here