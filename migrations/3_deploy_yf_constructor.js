const YFConstructor = artifacts.require("YFConstructor");

const { MichelsonMap } = require("@taquito/michelson-encoder");

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(YFConstructor, {
    admin: "tz1WBSTvfSC58wjHGsPeYkcftmbgscUybNuk",
    dtzToken: "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg",
    dtzYF: "tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg",
    deployFee: {
      deployFee: "10",
      deployAndStakeFee: "5",
      minStakeAmount: "5",
    },
    yieldFarmings: new MichelsonMap(),
  });
};
