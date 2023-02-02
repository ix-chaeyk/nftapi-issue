import { Contract } from "ethers";
import fs from "fs";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const verifyScriptFile = "output/verify-script";
let inited = false;

function getFilename(network: string) {
  return `output/verify-script.${network}`;
}

function initVerifyScript(network: string) {
  if (!inited) {
    fs.writeFileSync(getFilename(network), '#!/bin/bash\n\n', { mode: 0o755 });
    inited = true;
  }
}

export async function deployContract(hre: HardhatRuntimeEnvironment, name: string, ...parameters: any[]): Promise<Contract> {
  const network = hre.network.name;
  initVerifyScript(network);

  const contract = await hre.ethers.getContractFactory(name);
  const contractInstance = await contract.deploy(...parameters);
  await contractInstance.deployed();

  console.log(name + " deployed to:", contractInstance.address);
  fs.writeFileSync(
    getFilename(network),
    `npx hardhat verify --network ${network} ${contractInstance.address} ${parameters.join(' ')}\n`,
    { flag: 'a' }
  );

  return contractInstance;
}
