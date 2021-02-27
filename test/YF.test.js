const FA12 = artifacts.require("FA12");
const YF = artifacts.require("YF");

const accounts = require("../scripts/sandbox/accounts");

const { MichelsonMap } = require("@taquito/michelson-encoder");

const { bakeBlocks } = require("./utils/bakeBlocks");

contract("YF", async () => {
  var lpToken;
  var rewardToken;

  before("setup", async () => {
    const totalSupply = "10000";

    const lpTokenStorage = {
      totalSupply: totalSupply,
      ledger: MichelsonMap.fromLiteral({
        [accounts.alice.pkh]: {
          balance: totalSupply,
          allowances: MichelsonMap.fromLiteral({}),
        },
      }),
    };

    lpToken = await FA12.new(lpTokenStorage);

    const rewardTokenStorage = {
      totalSupply: totalSupply,
      ledger: MichelsonMap.fromLiteral({
        [accounts.alice.pkh]: {
          balance: totalSupply,
          allowances: MichelsonMap.fromLiteral({}),
        },
      }),
    };

    rewardToken = await FA12.new(rewardTokenStorage);

    const totalStaked = "0";
    const rewardPerShare = "0";
    const lastUpdateTime = "0";
    const ledger = new MichelsonMap();
    const yfParams = {
      lpToken: lpToken.address,
      miningParams: {
        rewardToken: rewardToken.address,
        lifetime: "31536000",
        periodInSeconds: "60",
        rewardPerPeriod: "1",
      },
    };

    const yfStorage = {
      totalStaked: totalStaked,
      rewardPerShare: rewardPerShare,
      lastUpdateTime: lastUpdateTime,
      ledger: ledger,
      yfParams: yfParams,
    };

    const instance = await YF.new(yfStorage);

    await rewardToken.transfer(
      accounts.alice.pkh,
      instance.address,
      totalSupply
    );
  });

  it("should stake", async () => {
    const instance = await YF.deployed();
    const amount = 5;

    await lpToken.approve(instance.address, amount.toString());

    const currentTime = Date.parse(
      (await tezos.rpc.getBlockHeader()).timestamp
    );

    await instance.stake(amount.toString());

    const storage = await instance.storage();
    const aliceRecord = await storage.ledger.get(accounts.alice.pkh);

    assert.strictEqual(Date.parse(storage.lastUpdateTime), currentTime);
    assert.strictEqual(storage.totalStaked.toNumber(), amount);
    assert.strictEqual(storage.rewardPerShare.toNumber(), 0);
    assert.strictEqual(aliceRecord.staked.toNumber(), amount);
    assert.strictEqual(aliceRecord.reward.toNumber(), 0);
    assert.strictEqual(aliceRecord.lastRewardPerShare.toNumber(), 0);
  });

  it("should claim and destribute rewards properly", async () => {
    const instance = await YF.deployed();
    const stakedByAlice = 5;

    await bakeBlocks(5);

    const currentTime = Date.parse(
      (await tezos.rpc.getBlockHeader()).timestamp
    );
    const prevStorage = await instance.storage();

    await instance.claim("");

    const rewardPerPeriod = 1;
    const deltaTime =
      (currentTime - Date.parse(prevStorage.lastUpdateTime)) / 1000;
    const reward = rewardPerPeriod * deltaTime;
    const rewardPerShare = Math.floor(reward / stakedByAlice);
    const aliceReward = stakedByAlice * rewardPerShare;
    const storage = await instance.storage();
    const aliceRecord = await storage.ledger.get(accounts.alice.pkh);
    const rewardTokenStorage = await rewardToken.storage();
    const aliceRecordInRewardToken = await rewardTokenStorage.ledger.get(
      accounts.alice.pkh
    );

    assert.strictEqual(
      aliceRecordInRewardToken.balance.toNumber(),
      aliceReward
    );
    assert.strictEqual(aliceRecord.staked.toNumber(), 5);
    assert.strictEqual(
      aliceRecord.lastRewardPerShare.toNumber(),
      rewardPerShare
    );
    assert.strictEqual(storage.totalStaked.toNumber(), 5);
    assert.strictEqual(storage.rewardPerShare.toNumber(), rewardPerShare);
  });

  it("should ustake", async () => {
    const instance = await YF.deployed();
    const stakedByAlice = 5;
    const amount = 3;

    await bakeBlocks(5);

    const currentTime = Date.parse(
      (await tezos.rpc.getBlockHeader()).timestamp
    );
    const prevStorage = await instance.storage();
    const prevAliceRecord = await prevStorage.ledger.get(accounts.alice.pkh);

    await instance.unstake(amount.toString());

    const rewardPerPeriod = 1;
    const deltaTime =
      (currentTime - Date.parse(prevStorage.lastUpdateTime)) / 1000;
    const reward = rewardPerPeriod * deltaTime;
    const rewardPerShare =
      Math.floor(reward / stakedByAlice) +
      prevStorage.rewardPerShare.toNumber();
    const aliceReward =
      stakedByAlice *
      (rewardPerShare - prevAliceRecord.lastRewardPerShare.toNumber());
    const storage = await instance.storage();
    const aliceRecord = await storage.ledger.get(accounts.alice.pkh);
    const lpTokenStorage = await lpToken.storage();
    const aliceRecordInLPToken = await lpTokenStorage.ledger.get(
      accounts.alice.pkh
    );
    const instanceRecordInLPToken = await lpTokenStorage.ledger.get(
      instance.address
    );

    assert.strictEqual(aliceRecordInLPToken.balance.toNumber(), 9998);
    assert.strictEqual(
      instanceRecordInLPToken.balance.toNumber(),
      stakedByAlice - amount
    );
    assert.strictEqual(aliceRecord.staked.toNumber(), 2);
    assert.strictEqual(aliceRecord.reward.toNumber(), aliceReward);
    assert.strictEqual(storage.totalStaked.toNumber(), 2);
    assert.strictEqual(storage.rewardPerShare.toNumber(), rewardPerShare);
  });
});
