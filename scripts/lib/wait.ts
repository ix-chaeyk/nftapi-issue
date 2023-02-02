export async function wait(seconds: number) {
  return new Promise((resolve) => {
    console.log(`waiting ${seconds} seconds...`);
    setTimeout(() => {
      resolve(undefined);
    }, seconds * 1000);
  });
}
