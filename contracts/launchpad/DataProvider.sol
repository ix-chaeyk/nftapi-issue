// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

import './NeowizERC721.sol';
import '../market/AsksV1.sol';
import '../market/RoyaltyFeeManager.sol';
import '../market/royaltyFeeHelpers/RoyaltyFeeSetter.sol';

contract DataProvider {
    constructor(
        AsksV1 asks_,
        RoyaltyFeeManager royaltyFeeManager_,
        RoyaltyFeeSetter royaltyFeeSetter_
    ) {
        asks = asks_;
        royaltyFeeManager = royaltyFeeManager_;
        royaltyFeeSetter = royaltyFeeSetter_;
    }

    struct RoundData {
        uint256 maxMintPerAccount;
        uint256 maxMint;
        uint256 totalMinted;
        uint256 price;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    AsksV1 public asks;
    RoyaltyFeeManager public royaltyFeeManager;
    RoyaltyFeeSetter public royaltyFeeSetter;

    function tokenURIBatch(address collection, uint256[] calldata tokenIds)
        external
        view
        returns (string[] memory)
    {
        NeowizERC721 n = NeowizERC721(collection);

        string[] memory result = new string[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            result[i] = n.tokenURI(tokenIds[i]);
        }

        return result;
    }

    /// @return royaltyRate 로열티율
    /// @return royaltyFeeSetterContractAddress 로열티율을 변경할 때 실행해야 하는 컨트랙트 주소
    /// @return royaltyReceiver 현재 컬렉션의 로열티를 수령하고 있는 주소
    /// @return royaltyFeeSetterContractOwner 모든 컬렉션의 로열티율을 변경할 수 있는 글로벌 setter 오너
    /// @return collectionContractOwner 특정 컬렉션의 로열티율을 변경할 수 있는 컨트랙트 오너
    function getRoyaltyData(address collection)
        external
        view
        returns (
            uint256 royaltyRate,
            address royaltyFeeSetterContractAddress,
            address royaltyReceiver,
            address royaltyFeeSetterContractOwner,
            address collectionContractOwner
        )
    {
        royaltyFeeSetterContractAddress = address(royaltyFeeSetter);
        royaltyFeeSetterContractOwner = royaltyFeeSetter.owner();
        (royaltyReceiver, royaltyRate) = royaltyFeeManager
            .calculateRoyaltyFeeAndGetRecipient(collection, 0, 10000);
        collectionContractOwner = Ownable(collection).owner();
    }

    /// @return feeRate 마켓플레이스 플랫폼 수수료율
    /// @return asksContractAddress 마켓플레이스 컨트랙트 주소
    /// @return asksContractOwnerAddress 마켓플레이스 컨트랙트 Owner 주소
    /// @return feeReceiver 마켓플레이스 fee 를 수령할 수 있는 주소
    function getMarketplaceFeeData()
        external
        view
        returns (
            uint256 feeRate,
            address asksContractAddress,
            address asksContractOwnerAddress,
            address feeReceiver
        )
    {
        // Denom = 10000
        feeRate = asks.fee();
        asksContractAddress = address(asks);
        asksContractOwnerAddress = asks.owner();
        feeReceiver = asks.protocolFeeRecipient();
    }

    function getTeamSupplyData(address neowizNftAddr)
        external
        view
        returns (
            uint256 totalTeamSupply,
            uint256 mintedTeamSupply,
            uint256 leftTeamSupply,
            address minter,
            address contractOwner
        )
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);
        contractOwner = n.owner();
        minter = n.owner();
        totalTeamSupply = n.TEAM_SUPPLY();
        mintedTeamSupply = n.totalTeamMinted();
        leftTeamSupply = totalTeamSupply - mintedTeamSupply;
    }

    function getPayment(address neowizNftAddr)
        external
        view
        returns (address payment)
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);
        payment = address(n.payment());
    }

    function getWithdrawableAmount(address neowizNftAddr)
        external
        view
        returns (uint256)
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);
        address payment = n.payment();

        if (address(payment) == address(0)) {
            return neowizNftAddr.balance;
        } else {
            return IERC20(payment).balanceOf(neowizNftAddr);
        }
    }

    function getRoundData(address neowizNftAddr)
        external
        view
        returns (RoundData[] memory result, address contractOwner)
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);
        uint256 numRounds = n.numRounds();
        contractOwner = n.owner();

        result = new RoundData[](numRounds);

        for (uint256 i = 0; i < numRounds; i++) {
            (
                result[i].maxMintPerAccount,
                result[i].maxMint,
                result[i].totalMinted,
                result[i].price,
                ,
                ,
                result[i].startTimestamp,
                result[i].endTimestamp
            ) = n.rounds(i + 1); // Round starts from 1
        }
    }

    function getMintingStatus(address neowizNftAddr)
        external
        view
        returns (
            uint256 totalNumberOfItem,
            uint256 accMintedAmount,
            uint256 burnedAmount,
            address contractOwner
        )
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);
        uint256 numRounds = n.numRounds();
        contractOwner = n.owner();

        // Round starts from 1
        for (uint256 i = 0; i < numRounds; i++) {
            (, uint256 maxMint, uint256 totalMinted, , , , , ) = n.rounds(
                i + 1
            );

            totalNumberOfItem += maxMint;
            accMintedAmount += totalMinted;
        }

        burnedAmount = _tryGetBurnedAmount(neowizNftAddr);
    }

    // This will be unused if all launchpad contract implement totalMinted function
    function _tryGetBurnedAmount(address neowizNftAddr)
        internal
        view
        returns (uint256)
    {
        NeowizERC721 n = NeowizERC721(neowizNftAddr);

        try n.totalMinted() returns (uint256 totalMinted) {
            uint256 burnedAmount = totalMinted - n.totalSupply();
            return burnedAmount;
        } catch {
            return 0;
        }
    }
}
