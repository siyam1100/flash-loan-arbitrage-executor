// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlashLoanSimple
 * @dev Professional implementation of an Aave V3 Flash Loan receiver.
 */
contract FlashLoanSimple is FlashLoanSimpleReceiverBase, Ownable {
    
    constructor(address _addressProvider) 
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
        Ownable(msg.sender)
    {}

    /**
     * @dev This function is called after your contract has received the flash loaned amount.
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // 1. ARBITRAGE LOGIC GOES HERE
        // Example: Swap 'asset' on DEX A and sell on DEX B
        
        // 2. Ensure we have enough to pay back
        uint256 amountToReturn = amount + premium;
        require(IERC20(asset).balanceOf(address(this)) >= amountToReturn, "Insufficient funds to repay loan");

        // 3. Approve Aave Pool to pull the repayment
        IERC20(asset).approve(address(POOL), amountToReturn);

        return true;
    }

    /**
     * @dev Triggers the flash loan process.
     */
    function requestFlashLoan(address _token, uint256 _amount) public onlyOwner {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    /**
     * @dev Allows owner to withdraw any profit (leftover tokens).
     */
    function withdraw(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    receive() external payable {}
}
