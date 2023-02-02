import { HardhatRuntimeEnvironment } from "hardhat/types";
import { loadContractConfig, saveContractConfig } from "./lib/config";
import { ethers } from "ethers";
import { deployContract } from "./lib/deploy";

export async function deployAsksV1(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  const contractConfig = await loadContractConfig(hre);
  if (!contractConfig.nft) {
    throw new Error('You should deploy nft.');
  }

  const sender = (await hre.ethers.getSigners())[0];

  const moduleManager = await deployContract(hre, "ModuleManager");
  const erc721TransferHelper = await deployContract(hre, "ERC721TransferHelper", moduleManager.address);
  const erc20TransferHelper = await deployContract(hre, "ERC20TransferHelper", moduleManager.address);
  const royaltyFeeRegistry = await deployContract(hre, "RoyaltyFeeRegistry", 5000 /* 50% */);
  const royaltyFeeManager = await deployContract(hre, "RoyaltyFeeManager", royaltyFeeRegistry.address);
  const currencyManager = await deployContract(hre, "CurrencyManager");
  const collectionManager = await deployContract(hre, "CollectionManager");
  const asksV1 = await deployContract(hre, "AsksV1",
    500, // fee, 5%
    sender.address, // protocolFeeRecipient
    erc20TransferHelper.address,
    erc721TransferHelper.address,
    royaltyFeeManager.address,
    currencyManager.address,
    collectionManager.address,
    ethers.constants.AddressZero, // trustedForwarder
    contractConfig.nft,
  );

  await moduleManager.setModuleRegistration(asksV1.address, true);
  await currencyManager.addCurrency("0x123455D0f27E9e6c4447322524d6f2Acd22f340A");
  await collectionManager.addToken(contractConfig.nft);

  const CYK721 = await hre.ethers.getContractFactory("ERC721");
  const cyk721 = CYK721.attach(contractConfig.nft);
  await cyk721.connect(sender).setApprovalForAll(erc721TransferHelper.address, true);

  await saveContractConfig(hre, {
    moduleManager: moduleManager.address,
    erc721TransferHelper: erc721TransferHelper.address,
    erc20TransferHelper: erc20TransferHelper.address,
    royaltyFeeRegistry: royaltyFeeRegistry.address,
    royaltyFeeManager: royaltyFeeManager.address,
    currencyManager: currencyManager.address,
    collectionManager: collectionManager.address,
    asksV1: asksV1.address,
  });
}
