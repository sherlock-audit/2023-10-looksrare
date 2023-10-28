// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";
import {IInfiltration} from "./interfaces/IInfiltration.sol";
import {IV3SwapRouter} from "./interfaces/IV3SwapRouter.sol";
import {IQuoterV2} from "./interfaces/IQuoterV2.sol";

contract InfiltrationPeriphery is LowLevelWETH {
    ITransferManager public immutable TRANSFER_MANAGER;
    IInfiltration public immutable INFILTRATION;
    IV3SwapRouter public immutable SWAP_ROUTER;
    IQuoterV2 public immutable QUOTER;
    address public immutable WETH;
    address public immutable LOOKS;

    uint24 private constant POOL_FEE = 3_000;

    constructor(
        address _transferManager,
        address _infiltration,
        address _uniswapRouter,
        address _uniswapQuoter,
        address _weth,
        address _looks
    ) {
        TRANSFER_MANAGER = ITransferManager(_transferManager);
        INFILTRATION = IInfiltration(_infiltration);
        SWAP_ROUTER = IV3SwapRouter(_uniswapRouter);
        QUOTER = IQuoterV2(_uniswapQuoter);
        WETH = _weth;
        LOOKS = _looks;

        address[] memory operators = new address[](1);
        operators[0] = address(INFILTRATION);
        TRANSFER_MANAGER.grantApprovals(operators);
    }

    /**
     * @notice Submits a heal request for the specified agent IDs.
     * @param agentIds The agent IDs to heal.
     */
    function heal(uint256[] calldata agentIds) external payable {
        uint256 costToHealInLOOKS = INFILTRATION.costToHeal(agentIds);

        IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: LOOKS,
            fee: POOL_FEE,
            recipient: address(this),
            amountOut: costToHealInLOOKS,
            amountInMaximum: msg.value,
            sqrtPriceLimitX96: 0
        });

        uint256 amountIn = SWAP_ROUTER.exactOutputSingle{value: msg.value}(params);

        IERC20(LOOKS).approve(address(TRANSFER_MANAGER), costToHealInLOOKS);

        INFILTRATION.heal(agentIds);

        if (msg.value > amountIn) {
            SWAP_ROUTER.refundETH();
            unchecked {
                _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, msg.value - amountIn, gasleft());
            }
        }
    }

    /**
     * @notice Returns the cost to heal the specified agents in ETH
     * @dev The cost doubles for each time the agent is healed.
     * @param agentIds The agent IDs to heal.
     * @return costToHealInETH The cost to heal the specified agents.
     */
    function costToHeal(uint256[] calldata agentIds) external returns (uint256 costToHealInETH) {
        uint256 costToHealInLOOKS = INFILTRATION.costToHeal(agentIds);

        IQuoterV2.QuoteExactOutputSingleParams memory params = IQuoterV2.QuoteExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: LOOKS,
            amount: costToHealInLOOKS,
            fee: POOL_FEE,
            sqrtPriceLimitX96: uint160(0)
        });

        (costToHealInETH, , , ) = QUOTER.quoteExactOutputSingle(params);
    }

    /**
     * @notice This function is used to receive ETH from the swap router.
     */
    receive() external payable {}
}
