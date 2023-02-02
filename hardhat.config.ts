import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-web3';
import '@nomiclabs/hardhat-etherscan';
import { deployNft } from './scripts/deployNft';
import { accounts } from './scripts/accounts';
import { publicMintWithPermit } from './scripts/publicMintWithPermit';
import { deployAsksV1 } from './scripts/deployAsksV1';
import { setUnRevealedURI } from './scripts/setUnRevealedURI';
import { requestRandomSeed } from './scripts/requestRandomSeed';
import { infuraTest } from './scripts/infuraTest';
import * as tdly from '@tenderly/hardhat-tenderly';
import { setBaseURI } from './scripts/setBaseURI';
import { config } from 'dotenv';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', accounts);
task('deployNft', 'Deploy NFT contract', deployNft);
task('deployAsksV1', 'Deploy AsksV1 contract', deployAsksV1);
task('setUnRevealedURI', 'Set unrevealed uri', setUnRevealedURI)
  .addPositionalParam('uri', 'unrevealed token\'s uri');
task('setBaseURI', 'Set base uri', setBaseURI)
  .addPositionalParam('uri', 'revealed token\'s uri');
task('publicMintWithPermit', 'Public mint with permit', publicMintWithPermit);
task('requestRandomSeed', 'Reveal', requestRandomSeed);
task('infuraTest', 'Infura NFT API test', infuraTest);

tdly.setup();
config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'mumbai',
  networks: {
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_APIKEY}`,
      httpHeaders: {
        'user-agent': 'IntellaX',
      },
      accounts: [
        '7e5271b14b7d1ad3a2eb0dd68328691295043989f0428ac647269e7e601257f5',
      ],
    },
  },
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  mocha: {
    timeout: 300000,
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.ETHERSCAN_APIKEY,
    },
  },
};
