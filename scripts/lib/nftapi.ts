import https from 'https';

export function getMetadata(chainId: string, tokenAddress: string, tokenId: string): Promise<any> {
  return new Promise((resolve, reject) => {
    try {
      https.get(`https://nft.api.infura.io/networks/${chainId}/nfts/${tokenAddress}/tokens/${tokenId}?resyncMetadata=true`, {
        headers: {
          authorization: 'Basic ' + Buffer.from(process.env.INFURA_APIKEY + ":" + process.env.INFURA_SECRET).toString('base64'),
        },
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          const body = JSON.parse(data);
          resolve(body);
        });
        res.on('error', (reason) => {
          console.log(reason);
          // ignore error
          resolve({});
        });
      });
    } catch (e) {
      console.log(e);
      // ignore error
      resolve({});
    }
  });
}
