import fs from "fs";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface IConfig {
  [key: string]: IContractConfig;
}

export interface IContractConfig {
  nft?: string;
  moduleManager?: string;
  erc721TransferHelper?: string;
  erc20TransferHelper?: string;
  royaltyFeeRegistry?: string;
  royaltyFeeManager?: string;
  currencyManager?: string;
  collectionManager?: string;
  asksV1?: string;
}

const configJson = "output/contract.json";

async function getChainId(hre: HardhatRuntimeEnvironment) {
  return (await hre.ethers.provider.getNetwork()).chainId;
}

function loadConfig(): IConfig {
  try {
    return JSON.parse(fs.readFileSync(configJson, "utf8")) as IConfig;
  } catch (e: any) {
    console.log("load config failed.", e.message);
    return {};
  }
}

export async function loadContractConfig(
  hre: HardhatRuntimeEnvironment
): Promise<IContractConfig> {
  const config = loadConfig();
  const chainId = await getChainId(hre);
  return config[chainId.toString()];
}

export async function saveContractConfig(
  hre: HardhatRuntimeEnvironment,
  contract: IContractConfig
) {
  const chainId = await getChainId(hre);

  const config = loadConfig();
  const before = config[chainId.toString()] ?? {};
  config[chainId.toString()] = { ...before, ...contract };
  fs.writeFileSync(configJson, JSON.stringify(config, null, "  "), "utf8");
}
