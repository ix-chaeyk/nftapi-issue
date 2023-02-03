# Infura NFT metadata API test

- Requires node 16 or higher.
- This program deploy nft contract and mint 10 tokens.
- NFT API returns unrevealed metadata at this point.
- Reveal NFT with requestRandomSeed(). Every NFT tokens are revealed.
- But NFT API returns unrevealed metadata. Now API's results are different with actual token's metadata.

# Prepare

You should create .env file
```
INFURA_APIKEY=xxxxx
INFURA_SECRET=yyyyy
```

And run
```
npm i
npx hardhat compile
```

# Run

```
npx hardhat infuraTest
```
