import { HardhatRuntimeEnvironment } from "hardhat/types";
import { loadContractConfig } from "./lib/config";

export async function setBaseURI(
  taskArgs: any,
  hre: HardhatRuntimeEnvironment
): Promise<void> {
  const contractConfig = await loadContractConfig(hre);
  if (!contractConfig.nft) {
    throw new Error('You should deploy nft contract.');
  }

  console.log('task args', JSON.stringify(taskArgs));

  const CYK721 = await hre.ethers.getContractFactory("BlockhashNeowizERC721");
  const cyk721 = CYK721.attach(contractConfig.nft);

  const result = await cyk721.setBaseURI(taskArgs.uri);
  console.log("hash", result.hash);

  await hre.ethers.provider.waitForTransaction(result.hash);
  const receipt = await hre.ethers.provider.getTransactionReceipt(result.hash);
  console.log(JSON.stringify(receipt));
}
