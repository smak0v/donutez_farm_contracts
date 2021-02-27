const { MichelsonMap } = require("@taquito/michelson-encoder");

const { oleh } = require("../scripts/sandbox/accounts");

const FactoryFA12 = artifacts.require("FactoryFA12");
const FactoryFA2 = artifacts.require("FactoryFA2");

contract("FactoryFA12", async () => {
  tezos.setProvider({
    config: {
      confirmationPollingTimeoutSecond: 1500,
    },
  });
  before("setup", async () => {
    fInstance = await FactoryFA12.deployed();
  });

  describe("launchToken", async () => {
    it("set a new Fa12Token", async () => {
      const amount = 4000000;

      await fInstance.main(amount);

      const fStorage = await fInstance.storage();
      var value = await fStorage.tokenList.get(oleh.pkh);

      console.log(value);
    });
  });
});

contract("FactoryFA2", async () => {
  tezos.setProvider({
    config: {
      confirmationPollingTimeoutSecond: 1500,
    },
  });
  before("setup", async () => {
    const f2Storage = {
      admin: "tz1TP5Are685mU29aAmTE6eBwRENwp1qhUdw",
      owner: "tz1TP5Are685mU29aAmTE6eBwRENwp1qhUdw",
      tokenList: new MichelsonMap(),
    };

    fInstance2 = await FactoryFA2.new(f2Storage);
  });

  describe("launchTokenFA2", async () => {
    it("set a new FA2Token", async () => {
      const amount = 4000000;
      const tokenMD = MichelsonMap.fromLiteral({
        [0]: {
          token_id: "0",
          extras: MichelsonMap.fromLiteral({
            [0]: Buffer.from(
              JSON.stringify({
                name: "Donutez Token",
                authors: ["DONUTEZ TEAM"],
              })
            ).toString("hex"),
          }),
        },
      });
      const MD = MichelsonMap.fromLiteral({
        [""]: Buffer.from("tezos-storage:here", "ascii").toString("hex"),
        here: Buffer.from(
          JSON.stringify({
            version: "v0.0.1",
            description: "Donutez Token",
            name: "Donutez Token",
            authors: ["DONUTEZ TEAM"],
            source: {
              tools: ["Ligo", "Flextesa"],
              location: "https://ligolang.org/",
            },
            interfaces: ["TZIP-12", "TZIP-16"],
            errors: [],
            views: [],
            tokens: {
              dynamic: [
                {
                  big_map: "tokenMD",
                },
              ],
            },
          }),
          "ascii"
        ).toString("hex"),
      });

      await fInstance2.main(amount, tokenMD, MD);

      const fStorage = await fInstance2.storage();

      var value = await fStorage.tokenList.get(oleh.pkh);

      console.log(value);
    });
  });
});
