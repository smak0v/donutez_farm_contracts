async function bakeBlocks(count) {
  for (let i = 0; i < count; i++) {
    const operation = await tezos.contract.transfer({
      to: await tezos.signer.publicKeyHash(),
      amount: 1,
    });

    await operation.confirmation();
  }
}

module.exports = {
  bakeBlocks,
};
