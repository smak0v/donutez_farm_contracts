const YFConstructor = artifacts.require("YFConstructor");
const FA12 = artifacts.require("FA12");
const YF = artifacts.require("YF");

const accounts = require("../scripts/sandbox/accounts");

const { MichelsonMap } = require("@taquito/michelson-encoder");

contract("YFConstructor", async () => {
  var dtzToken;
  var dtzLPToken;

  before("setup", async () => {
    const totalSupply = "10000";

    const dtzTokenStorage = {
      totalSupply: totalSupply,
      ledger: MichelsonMap.fromLiteral({
        [accounts.alice.pkh]: {
          balance: totalSupply,
          allowances: MichelsonMap.fromLiteral({}),
        },
      }),
    };

    dtzToken = await FA12.new(dtzTokenStorage);

    const dtzLPokenStorage = {
      totalSupply: totalSupply,
      ledger: MichelsonMap.fromLiteral({
        [accounts.alice.pkh]: {
          balance: totalSupply,
          allowances: MichelsonMap.fromLiteral({}),
        },
      }),
    };

    dtzLPToken = await FA12.new(dtzLPokenStorage);

    const admin = accounts.alice.pkh;
    const zeroAddress = "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg";
    const deployFee = "10";
    const deployAndStakeFee = "5";
    const minStakeAmount = "5";

    const yfConstructorStorage = {
      admin: admin,
      dtzToken: dtzToken.address,
      dtzYF: zeroAddress,
      deployFee: {
        deployFee: deployFee,
        deployAndStakeFee: deployAndStakeFee,
        minStakeAmount: minStakeAmount,
      },
      yieldFarmings: new MichelsonMap(),
    };

    await YFConstructor.new(yfConstructorStorage);
  });

  it("should deploy DTZ YF and setup it in YF constructor", async () => {
    const instance = await YFConstructor.deployed();
    const lpTokenAddress = dtzLPToken.address;
    const rewardToken = dtzToken.address;
    const lifetime = "31536000"; // 365 days
    const periodInSeconds = "15";
    const rewardPerPeriod = "5";
    const deployAndStake = false;
    const amountForStake = "0";
    const deployFee = "10";

    await dtzToken.approve(instance.address, deployFee);
    await instance.deployYF(
      lpTokenAddress,
      rewardToken,
      lifetime,
      periodInSeconds,
      rewardPerPeriod,
      deployAndStake,
      amountForStake
    );

    var storage = await instance.storage();
    const dtzYFAddress = await storage.yieldFarmings.get(accounts.alice.pkh)[0];

    await instance.setDTZYFAddress(dtzYFAddress);

    storage = await instance.storage();

    assert.strictEqual(dtzYFAddress, storage.dtzYF);
  });

  it("should set deploy fee", async () => {
    const instance = await YFConstructor.deployed();
    let storage = await instance.storage();

    assert.strictEqual(storage.deployFee.deployFee.toNumber(), 10);
    assert.strictEqual(storage.deployFee.deployAndStakeFee.toNumber(), 5);
    assert.strictEqual(storage.deployFee.minStakeAmount.toNumber(), 5);

    const deployFee = "15";
    const deployAndStakeFee = "7";
    const minStakeAmount = "10";

    await instance.setDeployFee(deployFee, deployAndStakeFee, minStakeAmount);
    storage = await instance.storage();

    assert.strictEqual(storage.deployFee.deployFee.toNumber(), 15);
    assert.strictEqual(storage.deployFee.deployAndStakeFee.toNumber(), 7);
    assert.strictEqual(storage.deployFee.minStakeAmount.toNumber(), 10);
  });

  it("should deploy YF", async () => {
    const instance = await YFConstructor.deployed();
    const lpTokenAddress = "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg";
    const rewardToken = "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg";
    const lifetime = "31536000"; // 365 days
    const periodInSeconds = "10";
    const rewardPerPeriod = "1";
    const deployAndStake = false;
    const amountForStake = "0";
    const deployFee = "15";

    await dtzToken.approve(instance.address, deployFee);
    await instance.deployYF(
      lpTokenAddress,
      rewardToken,
      lifetime,
      periodInSeconds,
      rewardPerPeriod,
      deployAndStake,
      amountForStake
    );

    const storage = await instance.storage();
    const dtzTokenStorage = await dtzToken.storage();
    const instanceAccount = await dtzTokenStorage.ledger.get(instance.address);

    assert.strictEqual(storage.yieldFarmings.get(accounts.alice.pkh).length, 2);
    assert.strictEqual(instanceAccount.balance.toNumber(), 25);
  });

  it("should withdraw DTZ tokens", async () => {
    const instance = await YFConstructor.deployed();

    await instance.withdrawDTZTokens("");
    await instance.withdrawDTZTokensCallback(25);

    const storage = await instance.storage();
    const dtzTokenStorage = await dtzToken.storage();
    const instanceAccount = await dtzTokenStorage.ledger.get(instance.address);
    const adminAccount = await dtzTokenStorage.ledger.get(storage.admin);

    assert.strictEqual(instanceAccount.balance.toNumber(), 0);
    assert.strictEqual(adminAccount.balance.toNumber(), 10000);
  });

  it("should set DTZ token address", async () => {
    const instance = await YFConstructor.deployed();

    await instance.setDTZTokenAddress(dtzToken.address);

    const storage = await instance.storage();

    assert.strictEqual(dtzToken.address, storage.dtzToken);
  });

  it("shoud deploy YF and stake with less comission for deployiong", async () => {
    const instance = await YFConstructor.deployed();
    const storage = await instance.storage();
    const lpTokenAddress = "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg";
    const rewardToken = "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg";
    const lifetime = "31536000"; // 365 days
    const periodInSeconds = "5";
    const rewardPerPeriod = "1";
    const deployAndStake = true;
    const amountForStake = "15";
    const deployFee = "7";

    await dtzToken.approve(instance.address, deployFee);
    await dtzLPToken.approve(storage.dtzYF, amountForStake);
    await instance.deployYF(
      lpTokenAddress,
      rewardToken,
      lifetime,
      periodInSeconds,
      rewardPerPeriod,
      deployAndStake,
      amountForStake
    );

    const dtzYF = await YF.at(storage.dtzYF);
    const dtzYFStorage = await dtzYF.storage();
    const dtzLPTokenStorage = await dtzLPToken.storage();
    const dtzLPTokenAccount = await dtzLPTokenStorage.ledger.get(dtzYF.address);

    assert.strictEqual(dtzYFStorage.totalStaked.toNumber(), 15);
    assert.strictEqual(dtzLPTokenAccount.balance.toNumber(), 15)
  });
});
