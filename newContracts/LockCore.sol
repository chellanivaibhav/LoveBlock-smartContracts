/// this contains all the variables for making sibling contracts that will be deployed individually 
/// and this is the starting point of smart contracts
pragma solidity ^0.4.16;
import "./LockOwnership.sol";
import "./LockBuySell.sol";

contract LockCore is LockOwnership , LockBuySell {
    function LockCore()  {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

    }
}