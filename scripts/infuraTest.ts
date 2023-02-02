import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { BigNumber, ethers } from 'ethers';
import { deployContract } from './lib/deploy';
import { getPermitSignature, makeDeadline } from './lib/permit';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { getMetadata } from './lib/nftapi';
import { wait } from './lib/wait';

const chainId = '80001';
const totalSupply = '10';
const price = '1';

export async function infuraTest(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  const signer = (await hre.ethers.getSigners())[0];

  const cyk721 = await deployContract(hre, 'BlockhashNeowizERC721',
    'CYK721', // name
    'CYK721', // symbol
    totalSupply, // maxTotalSupply
    '0', // teamSupply
    '0x156bc2186c73F4960b916cd554842F69321dD53C', // team address
    '0x123455D0f27E9e6c4447322524d6f2Acd22f340A', // payment token address
    'ipfs://QmQsxPtq2wwxWsTSSDidEo37YmeGNzS3XcWJy1MCVbrqjJ', // unrevealed uri
    '0xDA5EAfB2D6636EdAa83ceC3a35d88A2187F46D1c' // trustedForwarder
  );

  const startAt = new Date();

  const test = new InfuraTest(hre, signer, cyk721);
  await test.setBaseURI();
  await test.addRound();

  await test.mint(); // mint 10 nft tokens
  console.log('------------------ minted ----------------------');
  console.log();
  await test.getMetadata(['0'], 'unrevealed');

  await wait(30);
  console.log();
  console.log('We are expecting unrevealed nft metadata.');
  await test.getMetadata(['0'], 'unrevealed');

  await test.requestRandomSeed(); // reveal
  console.log();
  console.log('------------------ revealed ----------------------');
  console.log();

  console.log('Now every nft token is revealed.');
  console.log('We are waiting for revealed nft metadata to come back from the API.');
  console.log();
  let i = 1;
  let ids = ['0'];
  do {
    await wait(60);
    ids.push(i.toString());
    i++;
    const revealed = await test.getMetadata(ids, 'revealed');
    if (i === Number(totalSupply) || revealed.filter((v) => v && v !== 'Unrevealed').length > 0) {
      break;
    }
  } while (true);

  const endAt = new Date();

  console.log('started test', startAt);
  console.log('end     test', endAt);
}

class InfuraTest {

  constructor(private hre: HardhatRuntimeEnvironment, private signer: SignerWithAddress, private cyk721: ethers.Contract) {}

  async setBaseURI() {
    const result = await this.cyk721.setBaseURI('ipfs://QmSQA5UJE6mFgvUPthyRQeSFc6FhHY9KpMKFWZt7przUic/');
    await this.hre.ethers.provider.waitForTransaction(result.hash);
  }

  async addRound() {
    await this.cyk721.addRound(
      1, // PUBLIC
      1000000, // maxMintPerAccount
      1000000, // maxMint
      price,
      ethers.constants.HashZero, // merkleRoot
      Math.round(new Date().getTime() / 1000), // startTs
      Math.round(new Date('2100-01-01').getTime() / 1000) // endTs
    );
  }

  async mint() {
    const IX = await this.hre.ethers.getContractFactory('CYK');
    const ix = IX.attach('0x123455D0f27E9e6c4447322524d6f2Acd22f340A');

    const quantity = totalSupply;
    const round = '1';
    const price = '1';

    const deadline = makeDeadline(3600);
    const { v, r, s } = await getPermitSignature(
      this.signer,
      ix,
      this.cyk721.address,
      BigNumber.from(price).mul(BigNumber.from(quantity)),
      deadline
    );

    const result = await this.cyk721.publicMintWithPermit(
      quantity,
      round,
      ix.address,
      price,
      deadline,
      v,
      r,
      s
    );
    console.log('hash', result.hash);

    await this.hre.ethers.provider.waitForTransaction(result.hash);
    const receipt = await this.hre.ethers.provider.getTransactionReceipt(result.hash);
    const logs = receipt.logs.filter((v) => v.address === this.cyk721.address && v.topics[0].startsWith('0xddf252ad'));
    if (logs.length > 0) {
      logs.forEach((log) => {
        const tokenId = parseInt(log.topics[3]);
        console.log('tokenId ' + tokenId + ' just minted.');
      })
    } else {
      throw new Error('tokenId not found.');
    }
  }

  async requestRandomSeed() {
    const result = await this.cyk721.requestRandomSeed();
    await this.hre.ethers.provider.waitForTransaction(result.hash);
  }

  async getMetadata(tokenIds: string[], message: string) {
    return await Promise.all(tokenIds.map(async (tokenId) => {
      const metadata = await getMetadata(chainId, this.cyk721.address, tokenId);
      const attributes = metadata.metadata?.attributes;
      console.log(`API - token[${tokenId}] ${message} metadata attributes:`, attributes);

      if (attributes) {
        return attributes[0].value as string;
      } else {
        return undefined;
      }
    }));
  }
}

