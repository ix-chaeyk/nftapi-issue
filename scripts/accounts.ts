import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function accounts(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.web3.eth.getAccounts();

  for (const account of accounts) {
    console.log(account);
  }
}

