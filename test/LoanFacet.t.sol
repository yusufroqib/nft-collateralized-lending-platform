// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./helpers/DiamondDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol"; // For logging
import "../contracts/NFT.sol";

contract PresaleFacetTest is DiamondDeployer {
    string name = "Roccomania";
    string symbol = "RCO";
    NFT nftContract;

    // address NftAddress = address(ERC721_Diamond);

    function setUp() public virtual override {
        super.setUp(); // Call parent setUp first

        nftContract = new NFT(name, symbol);
    }

    function testPresale_MinimumPurchase() public {
                console.logAddress(address(nftContract));

    }

    // function testFailPresale_InvalidProof() public {
    //     // Use non-whitelisted address
    //     vm.startPrank(user1);

    //     // Try to use proof from first whitelisted address
    //     bytes32[] memory proof = whitelistData.proofs[
    //         whitelistData.addresses[0]
    //     ];

    //     // vm.expectRevert(PresaleFacet.InvalidProof.selector);
    //     Presale_Diamond.mintPresale{value: 1 ether}(proof);

    //     vm.stopPrank();
    // }

    // // function diamondCut(
    // //     FacetCut[] calldata _diamondCut,
    // //     address _init,
    // //     bytes calldata _calldata
    // // ) external override {}
}
