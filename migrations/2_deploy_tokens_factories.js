const FactoryFA12 = artifacts.require("FactoryFA12");
const FactoryFA2 = artifacts.require("FactoryFA2");

const { MichelsonMap } = require("@taquito/michelson-encoder");

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(FactoryFA12, {
    admin: "tz1WBSTvfSC58wjHGsPeYkcftmbgscUybNuk",
    owner: "tz1WBSTvfSC58wjHGsPeYkcftmbgscUybNuk",
    tokenList: new MichelsonMap(),
  });
  deployer.deploy(FactoryFA2, {
    admin: "tz1WBSTvfSC58wjHGsPeYkcftmbgscUybNuk",
    owner: "tz1WBSTvfSC58wjHGsPeYkcftmbgscUybNuk",
    tokenList: new MichelsonMap(),
  });
};
