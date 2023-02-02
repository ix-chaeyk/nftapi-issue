import { HardhatRuntimeEnvironment } from "hardhat/types";
import { loadContractConfig } from "./lib/config";
import { BigNumber } from "ethers";
import { makeDeadline, getPermitSignature } from "./lib/permit";

export async function publicMintWithPermit(
  taskArgs: any,
  hre: HardhatRuntimeEnvironment
) {
  const contractConfig = await loadContractConfig(hre);
  if (!contractConfig.nft) {
    throw new Error('You should deploy nft contract.');
  }

  const sender = (await hre.ethers.getSigners())[0];

  const CYK721 = await hre.ethers.getContractFactory("BlockhashNeowizERC721");
  const cyk721 = CYK721.attach(contractConfig.nft);

  const IX = await hre.ethers.getContractFactory("CYK");
  const ix = IX.attach("0x123455D0f27E9e6c4447322524d6f2Acd22f340A");

  const quantity = "10";
  const round = "1";
  const price = "1";

  const deadline = makeDeadline(3600);
  const { v, r, s } = await getPermitSignature(
    sender,
    ix,
    cyk721.address,
    BigNumber.from(price).mul(BigNumber.from(quantity)),
    deadline
  );

  const result = await cyk721.publicMintWithPermit(
    quantity,
    round,
    ix.address,
    price,
    deadline,
    v,
    r,
    s
  );
  console.log("hash", result.hash);

  await hre.ethers.provider.waitForTransaction(result.hash);
  const receipt = await hre.ethers.provider.getTransactionReceipt(result.hash);
  const logs = receipt.logs.filter((v) => v.address === cyk721.address && v.topics[0].startsWith('0xddf252ad'));
  if (logs.length > 0) {
    logs.forEach((log) => {
      const tokenId = parseInt(log.topics[3]);
      console.log("tokenId " + tokenId + " just minted.");
    })
  } else {
    throw new Error("tokenId not found.");
  }
}
