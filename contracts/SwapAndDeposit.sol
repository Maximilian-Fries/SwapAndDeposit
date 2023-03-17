// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/IERC20.sol";
import "../interfaces/CTokenI.sol";
import "../interfaces/UniswapI.sol";

contract SwapAndDeposit {
    address owner;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event MyLog(string, uint256);

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender, "No sufficient right");
        _;
    }

    function setOwner(address newOwner) external ownerOnly {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    // TODO: create a map from tokens to addresses.

    // adapt the method for tokenIn = ETH. Account has to send ETH in call message. Then the ETH can be swaped for tokenOut
    // add case when tokenIn == tokenOut

    function swapAndDepositErc20forETH(
        address _tokenIn,
        uint256 _amountIn
    ) external {
        // In order for this transaction to work, msg.sender must have signed IERC20(_tokenIn).approve(address(this), _amountIn)
        require(
            IERC20(_tokenIn).allowance(msg.sender, address(this)) >= _amountIn,
            "Insuficient Allowance"
        );
        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn),
            "transferFrom failed."
        );
        require(
            IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn),
            "approve failed."
        );

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WETH;

        uint256 amountOutMin = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path)[path.length - 1];

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactTokensForETH(
                _amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        uint256 amountOut = amounts[amounts.length - 1];
        CEth cToken = CEth(payable(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5));

        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();

        cToken.mint{value: amountOut, gas: 250000}();
        emit MyLog(
            "Supplied ETH to Compound. Current supply rate (scaled by 1e18) is ",
            supplyRateMantissa
        );

        cToken.transfer(msg.sender, cToken.balanceOf(address(this)));
    }

    function swapAndDepositETHforErc20(
        address _tokenOut,
        address _ctokenOut
    ) external payable {
        uint256 input_eth = msg.value;
        require(input_eth > 0, "This message got no eth");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenOut;

        uint256 amountOutMin = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(input_eth, path)[path.length - 1];
        require(amountOutMin > 0, "Minimum ouptut must be larger than zero");

        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactETHForTokens{value: input_eth}(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountOut = amounts[amounts.length - 1];
        supplyErc20ToCompound(_tokenOut, _ctokenOut, amountOut, msg.sender);
    }

    function swapAndDepositErc20forErc20(
        address _tokenIn,
        address _tokenOut,
        address _ctokenOut,
        uint256 _amountIn
    ) external {
        // In order for this transaction to work, msg.sender must have signed IERC20(_tokenIn).approve(address(this), _amountIn)
        require(
            IERC20(_tokenIn).allowance(msg.sender, address(this)) >= _amountIn,
            "Insuficient Allowance"
        );
        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn),
            "transferFrom failed."
        );
        require(
            IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn),
            "approve failed."
        );

        // Define the path for swapping the tokens.
        address[] memory path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;

        // Here we swap the tokens and send them to the contract
        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(
                _amountIn,
                IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(
                    _amountIn,
                    path
                )[path.length - 1],
                path,
                address(this),
                block.timestamp
            );
        uint256 amountOut = amounts[amounts.length - 1];

        // deposit _tokenOut in Compound

        supplyErc20ToCompound(_tokenOut, _ctokenOut, amountOut, msg.sender);
    }

    // TODO: create an IWantMyTokensBack function

    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply,
        address _tokenOwner
    ) public {
        // Create a reference to the underlying asset contract.
        IERC20 underlying = IERC20(_erc20Contract);

        // Create a reference to the corresponding cToken contract
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _numTokensToSupply);

        // Mint cTokens
        assert(cToken.mint(_numTokensToSupply) == 0);

        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog(
            "Supplied ETH to Compound. Current supply rate (scaled by 1e18) is ",
            supplyRateMantissa
        );

        cToken.transfer(_tokenOwner, cToken.balanceOf(address(this)));
    }

    receive() external payable {}
}
