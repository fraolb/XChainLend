// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IERC165} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol";

abstract contract LendProtocol is CCIPReceiver, OwnerIsCreator {
    error Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
    error Error__DepositCollateralFailed();

    IERC20[] private s_tokenAddresses;
    // mapped the price feed and the routers to the addresses correspondly
    mapping(address token => address priceFeed) s_priceFeeds;
    mapping(address token => IRouterClient router) s_routers;

    // Depsitor Address => Deposited Token Address ==> amount
    mapping(address => mapping(address => uint256)) public s_deposits;
    // Depsitor Address => Borrowed Token Address ==> amount
    mapping(address => mapping(address => uint256)) public s_borrowings;

    /*
     * @notice The constructor takes the router addresses and the tokens that are transferrable
     * @param _routers takes the addresses of router contracts
     * @param _tokens is the tokens that users lend and borrow
     */
    constructor(address[] memory _routers, address[] memory _tokenAddresses, address[] memory priceFeedAddresses) {
        if (_routers.length != _tokenAddresses.length || _tokenAddresses.length != priceFeedAddresses.length) {
            revert Error__TokenAddressesAndRoutersAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < _routers.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = priceFeedAddresses[i];
            s_tokenAddresses.push(IERC20(_tokenAddresses[i]));
            s_routers[_tokenAddresses[i]] = IRouterClient(_routers[i]);
        }
    }

    function depositCollateral(address tokenCollateralAddress, uint256 collateralAmount) external {
        s_deposits[msg.sender][tokenCollateralAddress] += collateralAmount;
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) {
            revert Error__DepositCollateralFailed();
        }
    }
}
