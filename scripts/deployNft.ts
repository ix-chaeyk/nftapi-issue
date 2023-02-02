import { HardhatRuntimeEnvironment } from "hardhat/types";
import { saveContractConfig } from "./lib/config";
import { ethers } from "ethers";
import { deployContract } from "./lib/deploy";

export async function deployNft(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  const cyk721 = await deployContract(hre, "BlockhashNeowizERC721",
    "CYK721", // name
    "CYK721", // symbol
    "10", // maxTotalSupply
    "0", // teamSupply
    "0x156bc2186c73F4960b916cd554842F69321dD53C", // team address
    "0x123455D0f27E9e6c4447322524d6f2Acd22f340A", // payment token address
    "ipfs://QmQsxPtq2wwxWsTSSDidEo37YmeGNzS3XcWJy1MCVbrqjJ", // unrevealed uri
    "0xDA5EAfB2D6636EdAa83ceC3a35d88A2187F46D1c" // trustedForwarder
  );

  await cyk721.setBaseURI('ipfs://QmQsxPtq2wwxWsTSSDidEo37YmeGNzS3XcWJy1MCVbrqjJ/');

  await cyk721.addRound(
    1, // PUBLIC
    10, // maxMintPerAccount
    10, // maxMint
    "1", // price
    ethers.constants.HashZero, // merkleRoot
    Math.round(new Date().getTime() / 1000), // startTs
    Math.round(new Date("2100-01-01").getTime() / 1000) // endTs
  );

  await saveContractConfig(hre, { nft: cyk721.address });
}
