//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";

// ----------------------INTERFACE------------------------------

// Aave
// https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool

interface ILendingPool {
    /**
     * Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of theliquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// UniswapV2

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/Pair-ERC-20
interface IERC20 {
    // Returns the account balance of another account with address _owner.
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Allows _spender to withdraw from your account multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     * Lets msg.sender set their allowance for a spender.
     **/
    function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT

    /**
     * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     * Lets msg.sender send pool tokens to an address.
     **/
    function transfer(address to, uint256 value) external returns (bool);
}

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH is IERC20 {
    // Convert the wrapped token back to Ether.
    function withdraw(uint256) external;
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol
// The flash loan liquidator we plan to implement this time should be a UniswapV2 Callee
interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory
interface IUniswapV2Factory {
    // Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0).
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/pair
interface IUniswapV2Pair {
    /**
     * Swaps tokens. For regular swaps, data.length must be 0.
     * Also see [Flash Swaps](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps).
     **/
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * Returns the reserves of token0 and token1 used to price trades and distribute liquidity.
     * See Pricing[https://docs.uniswap.org/protocol/V2/concepts/advanced-topics/pricing].
     * Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
     **/
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// ----------------------IMPLEMENTATION------------------------------

contract LiquidationOperator is IUniswapV2Callee {
    uint8 public constant health_factor_decimals = 18;

    // TODO: define constants used in the contract including ERC-20 tokens, Uniswap Pairs, Aave lending pools, etc. */

    IERC20 constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IUniswapV2Factory constant uniswapV2Factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Pair immutable uniswapV2Pair_WETH_USDT; // Pool1
    IUniswapV2Pair immutable uniswapV2Pair_WBTC_WETH; // Pool2
    IUniswapV2Pair immutable uniswapV2Pair_WBTC_USDT; // Pool3
    IUniswapV2Pair immutable uniswapV2Pair_USDC_WETH; // Pool4
    IUniswapV2Pair immutable uniswapV2Pair_USDC_USDT; // Pool5

    ILendingPool constant lendingPool =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    address liquidationTarget;
    IUniswapV2Pair uniswapV2Pair_A_B;

    // uint debt_USDT;

    // END TODO

    // some helper function, it is totally fine if you can finish the lab without using these function
    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // some helper function, it is totally fine if you can finish the lab without using these function
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function safeUSDTTransfer(address to, uint256 value) internal {
        (bool success, bytes memory data) = address(USDT).call(
            abi.encodeWithSelector(0xa9059cbb /* transfer */, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "USDT_TRANSFER_FAILED"
        );
    }

    constructor() {
        // TODO: (optional) initialize your contract

        uniswapV2Pair_WETH_USDT = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(WETH), address(USDT))
        ); // Pool1
        uniswapV2Pair_WBTC_WETH = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(WBTC), address(WETH))
        ); // Pool2
        uniswapV2Pair_WBTC_USDT = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(WBTC), address(USDT))
        ); // Pool3
        uniswapV2Pair_USDC_WETH = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(WETH), address(USDC))
        ); // Pool4
        uniswapV2Pair_USDC_USDT = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(USDT), address(USDC))
        ); // Pool5
        // debt_USDT = 2916378221684;

        // END TODO
    }

    // TODO: add a `receive` function so that you can withdraw your WETH

    receive() external payable {}

    // END TODO

    // required by the testing script, entry for your liquidation call
    function operate(
        address _token0,
        address _token1,
        uint256 _debt0,
        uint256 _debt1,
        address _liquidationTarget,
        bool _profitWithEth
    ) external {
        // TODO: implement your liquidation logic

        // 0. security checks and initializing variables

        liquidationTarget = _liquidationTarget;

        // 1. get the target user account data & make sure it is liquidatable

        uint256 totalCollateralETH;
        uint256 totalDebtETH;
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        (
            totalCollateralETH,
            totalDebtETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = lendingPool.getUserAccountData(liquidationTarget);
        // console.log("%s %s %s", liquidationTarget, healthFactor, block.number);
        require(
            healthFactor < (10 ** health_factor_decimals),
            "Cannot liquidate; health factor must be below 1"
        );

        uniswapV2Pair_A_B = IUniswapV2Pair(
            uniswapV2Factory.getPair(_token0, _token1)
        );

        // 2. call flash swap to liquidate the target user
        // based on https://etherscan.io/tx/0xac7df37a43fab1b130318bbb761861b8357650db2e2c6493b73d6da3d9581077
        // we know that the target user borrowed USDT with WBTC as collateral
        // we should borrow USDT, liquidate the target user and get the WBTC, then swap WBTC to repay uniswap
        // (please feel free to develop other workflows as long as they liquidate the target user successfully)
        bytes memory data = abi.encode(
            address(uniswapV2Pair_A_B),
            _profitWithEth
        );
        uniswapV2Pair_A_B.swap(_debt0, _debt1, address(this), data);

        // 3. Convert the profit into ETH and send back to sender

        uint balance = WETH.balanceOf(address(this));
        WETH.withdraw(balance);
        payable(msg.sender).transfer(address(this).balance);

        // END TODO
    }

    // required by the swap
    function _uniswapV2Call_WETH_USDT(
        address,
        uint256,
        uint256 amount1,
        bytes calldata
    ) private {
        // TODO: implement your liquidation logic
        // 2.0. security checks and initializing variables

        assert(msg.sender == address(uniswapV2Pair_WETH_USDT));
        (
            uint256 reserve_WETH_Pool1,
            uint256 reserve_USDT_Pool1,

        ) = uniswapV2Pair_WETH_USDT.getReserves(); // Pool1

        (
            uint256 reserve_WBTC_Pool2,
            uint256 reserve_WETH_Pool2,

        ) = uniswapV2Pair_WBTC_WETH.getReserves(); // Pool2

        // 2.1 liquidate the target user

        uint debtToCover = amount1; // => debtToCover = debt_USDT
        USDT.approve(address(lendingPool), debtToCover);
        lendingPool.liquidationCall(
            address(WBTC),
            address(USDT),
            liquidationTarget,
            debtToCover,
            false
        );
        uint collateral_WBTC = WBTC.balanceOf(address(this));

        // 2.2 swap WBTC for other things or repay directly

        WBTC.transfer(address(uniswapV2Pair_WBTC_WETH), collateral_WBTC);
        uint amountOut_WETH = getAmountOut(
            collateral_WBTC,
            reserve_WBTC_Pool2,
            reserve_WETH_Pool2
        );
        uniswapV2Pair_WBTC_WETH.swap(0, amountOut_WETH, address(this), "");

        // 2.3 repay

        uint repay_WETH = getAmountIn(
            debtToCover,
            reserve_WETH_Pool1,
            reserve_USDT_Pool1
        );
        WETH.transfer(address(uniswapV2Pair_WETH_USDT), repay_WETH);

        // END TODO
    }

    // required by the swap
    function _uniswapV2Call_WBTC_USDT(
        address,
        uint256,
        uint256 amount1,
        bytes calldata
    ) private {
        // TODO: implement your liquidation logic
        // 2.0. security checks and initializing variables

        //already check that token0 is WBTC, token1 is USDT : https://etherscan.io/address/0x0DE0Fa91b6DbaB8c8503aAA2D1DFa91a192cB149#readContract

        assert(msg.sender == address(uniswapV2Pair_A_B));
        assert(address(uniswapV2Pair_WBTC_USDT) == address(uniswapV2Pair_A_B));
        (
            uint256 reserve_WBTC_Pool1,
            uint256 reserve_USDT_Pool1,

        ) = uniswapV2Pair_WBTC_USDT.getReserves();

        (
            uint256 reserve_WBTC_Pool2,
            uint256 reserve_WETH_Pool2,

        ) = uniswapV2Pair_WBTC_WETH.getReserves();

        // 2.1 liquidate the target user

        uint debtToCover = amount1; // => debtToCover = debt_USDT
        USDT.approve(address(lendingPool), debtToCover);
        lendingPool.liquidationCall(
            address(WBTC),
            address(USDT),
            liquidationTarget,
            debtToCover,
            false
        );
        // uint collateral_WBTC = WBTC.balanceOf(address(this));

        // 2.2 repay

        uint repay_WBTC = getAmountIn(
            debtToCover,
            reserve_WBTC_Pool1,
            reserve_USDT_Pool1
        );
        // console.log("balance_WBTC: %s", WBTC.balanceOf(address(this)));
        // console.log("repay_WBTC: %s", repay_WBTC);
        WBTC.transfer(address(uniswapV2Pair_WBTC_USDT), repay_WBTC);

        // 2.3 convert WBTC to WETH

        uint balance_WBTC = WBTC.balanceOf(address(this));
        uint amountOut_WETH = getAmountOut(
            balance_WBTC,
            reserve_WBTC_Pool2,
            reserve_WETH_Pool2
        );
        WBTC.transfer(address(uniswapV2Pair_WBTC_WETH), balance_WBTC);
        uniswapV2Pair_WBTC_WETH.swap(0, amountOut_WETH, address(this), "");

        // END TODO
    }

    // required by the swap
    function _uniswapV2Call_USDC_WETH_ProfitUSDC(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) private {
        // TODO: implement your liquidation logic
        // 2.0. security checks and initializing variables

        //already check that token0 is WBTC, token1 is USDT : https://etherscan.io/address/0x0DE0Fa91b6DbaB8c8503aAA2D1DFa91a192cB149#readContract

        assert(msg.sender == address(uniswapV2Pair_A_B));
        assert(address(uniswapV2Pair_USDC_WETH) == address(uniswapV2Pair_A_B));

        (
            uint256 reserve_WETH_Pool1,
            uint256 reserve_USDT_Pool1,

        ) = uniswapV2Pair_WETH_USDT.getReserves();
        (
            uint256 reserve_USDC_Pool2,
            uint256 reserve_USDT_Pool2,

        ) = uniswapV2Pair_USDC_USDT.getReserves();

        // 2.1 liquidate the target user

        uint debtToCover = amount0; // => debtToCover = debt_USDT
        USDC.approve(address(lendingPool), debtToCover);
        lendingPool.liquidationCall(
            address(WETH),
            address(USDC),
            liquidationTarget,
            debtToCover,
            false
        );
        uint collateral_WETH = WETH.balanceOf(address(this));

        // 2.2 swap WETH -> USDT

        WETH.transfer(address(uniswapV2Pair_WETH_USDT), collateral_WETH);
        uint amountOut_USDT = getAmountOut(
            collateral_WETH,
            reserve_WETH_Pool1,
            reserve_USDT_Pool1
        );
        uniswapV2Pair_WETH_USDT.swap(0, amountOut_USDT, address(this), "");

        // 2.3 swap USDT -> USDC

        safeUSDTTransfer(address(uniswapV2Pair_USDC_USDT), amountOut_USDT);
        uint amountOut_USDC = getAmountOut(
            amountOut_USDT,
            reserve_USDT_Pool2,
            reserve_USDC_Pool2
        );
        uniswapV2Pair_USDC_USDT.swap(amountOut_USDC, 0, address(this), "");

        // 2.4 repay USDC & swap USDC remaining to WETH

        // console.log("debtToCover: %s", debtToCover);
        uint debtToCoverWithMargin = ((debtToCover * 100301) / 100000);
        uint remaining_USDC = USDC.balanceOf(address(this));
        require(
            remaining_USDC >= debtToCoverWithMargin,
            "Not enough token to cover the debt"
        );
        USDC.transfer(address(uniswapV2Pair_USDC_WETH), debtToCoverWithMargin);
        USDC.transfer(tx.origin, remaining_USDC - debtToCoverWithMargin);

        // Can't swap USDC->WETH in `uniswapV2Call` of uniswapV2Pair_USDC_WETH
        //  (
        //     uint256 reserve_USDC_Pool3,
        //     uint256 reserve_WETH_Pool3,

        // ) = uniswapV2Pair_USDC_WETH.getReserves();

        // uint balance_USDC = USDC.balanceOf(address(this));
        // uint amountOut_WETH = getAmountOut(
        //     remaining_USDC - debtToCover,
        //     reserve_USDC_Pool3,
        //     reserve_WETH_Pool3
        // );
        // USDC.transfer(address(uniswapV2Pair_USDC_WETH), balance_USDC);
        // uniswapV2Pair_USDC_WETH.swap(0, amountOut_WETH, address(this), "");

        // END TODO
    }

    function _uniswapV2Call_USDC_WETH_ProfitWETH1(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) private {
        // TODO: implement your liquidation logic
        // 2.0. security checks and initializing variables

        //already check that token0 is WBTC, token1 is USDT : https://etherscan.io/address/0x0DE0Fa91b6DbaB8c8503aAA2D1DFa91a192cB149#readContract

        assert(msg.sender == address(uniswapV2Pair_A_B));
        assert(address(uniswapV2Pair_USDC_WETH) == address(uniswapV2Pair_A_B));

        (
            uint256 reserve_WETH_Pool1,
            uint256 reserve_USDT_Pool1,

        ) = uniswapV2Pair_WETH_USDT.getReserves();
        (
            uint256 reserve_USDC_Pool2,
            uint256 reserve_USDT_Pool2,

        ) = uniswapV2Pair_USDC_USDT.getReserves();

        // Get final repay USDC
        uint debtToCover = amount0; // => debtToCover = debt_USDC
        uint debtToCoverWithMargin_USDC = ((debtToCover * 100301) / 100000);

        // 2.1 liquidate the target user

        USDC.approve(address(lendingPool), debtToCover);
        lendingPool.liquidationCall(
            address(WETH),
            address(USDC),
            liquidationTarget,
            debtToCover,
            false
        );

        // 2.2.1 Get amountIn_USDC for swap USDT -> USDC

        uint amountIn_USDT = getAmountIn(
            debtToCoverWithMargin_USDC,
            reserve_USDT_Pool2,
            reserve_USDC_Pool2
        );

        // 2.2.2 Get amountIn_WETH fro swap WETH -> USDT

        uint amountIn_WETH = getAmountIn(
            amountIn_USDT,
            reserve_WETH_Pool1,
            reserve_USDT_Pool1
        );

        // 2.3 swap WETH -> USDT

        WETH.transfer(address(uniswapV2Pair_WETH_USDT), amountIn_WETH);
        uniswapV2Pair_WETH_USDT.swap(0, amountIn_USDT, address(this), "");

        // 2.4 swap USDT -> USDC

        safeUSDTTransfer(address(uniswapV2Pair_USDC_USDT), amountIn_USDT);
        uniswapV2Pair_USDC_USDT.swap(
            debtToCoverWithMargin_USDC,
            0,
            address(this),
            ""
        );

        // 2.4 repay USDC & swap USDC remaining to WETH

        USDC.transfer(
            address(uniswapV2Pair_USDC_WETH),
            debtToCoverWithMargin_USDC
        );

        require(WETH.balanceOf(address(this)) > 0, "No profit from liquidation");

        // END TODO
    }
    
    function _uniswapV2Call_USDC_WETH_ProfitWETH2(
        address,
        uint256 amount0,
        uint256,
        bytes calldata
    ) private {
        // TODO: implement your liquidation logic
        // 2.0. security checks and initializing variables

        //already check that token0 is WBTC, token1 is USDT : https://etherscan.io/address/0x0DE0Fa91b6DbaB8c8503aAA2D1DFa91a192cB149#readContract

        assert(msg.sender == address(uniswapV2Pair_A_B));
        assert(address(uniswapV2Pair_USDC_WETH) == address(uniswapV2Pair_A_B));

        (
            uint256 reserve_USDC_Pool,
            uint256 reserve_WETH_Pool,
        ) = uniswapV2Pair_USDC_WETH.getReserves();

        // Get final repay USDC
        uint debtToCover = amount0; // => debtToCover = debt_USDC

        // 2.1 liquidate the target user

        USDC.approve(address(lendingPool), debtToCover);
        lendingPool.liquidationCall(
            address(WETH),
            address(USDC),
            liquidationTarget,
            debtToCover,
            false
        );

        uint amountIn_WETH = getAmountIn(
            debtToCover,
            reserve_WETH_Pool,
            reserve_USDC_Pool
        );

        WETH.transfer(address(uniswapV2Pair_USDC_WETH), amountIn_WETH);
       
        require(WETH.balanceOf(address(this)) > 0, "No profit from liquidation");

        // END TODO
    }

    function uniswapV2Call(
        address to,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        (address uniswapV2Pair, bool profitWithEth) = abi.decode(
            data,
            (address, bool)
        );
        if (uniswapV2Pair == address(uniswapV2Pair_WETH_USDT)) {
            _uniswapV2Call_WETH_USDT(to, amount0, amount1, data);
        }
        if (uniswapV2Pair == address(uniswapV2Pair_WBTC_USDT)) {
            _uniswapV2Call_WBTC_USDT(to, amount0, amount1, data);
        }
        if (uniswapV2Pair == address(uniswapV2Pair_USDC_WETH)) {
            if (profitWithEth) {
                _uniswapV2Call_USDC_WETH_ProfitWETH2(to, amount0, amount1, data);
            } else {
                _uniswapV2Call_USDC_WETH_ProfitUSDC(to, amount0, amount1, data);
            }
        }
    }

    // function getReserve_DAI_WETH() external {
    //     (
    //         uint256 reserve_DAI_Pool,
    //         uint256 reserve_WETH_Pool,

    //     ) = uniswapV2Pair_DAI_WETH.getReserves();
    //     console.log("%s %s", reserve_DAI_Pool, reserve_WETH_Pool);
    // }
}
