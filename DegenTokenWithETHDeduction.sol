// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegenTokenWithETHDeduction is ERC20, Ownable {
    uint256 public fixedEthCommission;  // Fixed ETH commission per transfer
    address public commissionPool;      // Address where the commission ETH will be sent

    event CommissionUpdated(uint256 newCommission);
    event PoolAddressUpdated(address newPool);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address pool,
        uint256 initialCommission,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        require(pool != address(0), "Pool address cannot be zero");
        require(initialCommission > 0, "Commission must be greater than zero");

        commissionPool = pool;
        fixedEthCommission = initialCommission;

        _mint(initialOwner, initialSupply);  // Mint initial supply to the specified owner
    }

    function setFixedEthCommission(uint256 _commission) external onlyOwner {
        require(_commission > 0, "Commission must be greater than zero");
        fixedEthCommission = _commission;
        emit CommissionUpdated(_commission);
    }

    function setCommissionPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Pool address cannot be zero");
        commissionPool = _pool;
        emit PoolAddressUpdated(_pool);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     * This includes minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Skip checks for minting or burning
        if (from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        // Check sender's ETH balance for the commission
        require(address(from).balance >= fixedEthCommission, "Insufficient ETH for commission");

        // Deduct the ETH commission
        (bool success, ) = commissionPool.call{value: fixedEthCommission}("");
        require(success, "Failed to send ETH commission to pool");

        super._beforeTokenTransfer(from, to, amount);
    }

    // Allow the contract to receive ETH for operational purposes if needed
    receive() external payable {}
}
