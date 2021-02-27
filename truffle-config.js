const { alice } = require("./scripts/sandbox/accounts");

module.exports = {
  contracts_directory: "./contracts/main",
  networks: {
    development: {
      host: "http://localhost",
      port: 8732,
      network_id: "*",
      secretKey: alice.sk,
      type: "tezos",
    },
    delphinet: {
      host: "https://delphinet.smartpy.io",
      port: 443,
      network_id: "*",
      secretKey: "edskS3DCtGJsveC5MLQarnzEaWnLTsPHhqDediHEPadoJWT1PLLHQzwgnP4uttw7Hme9kzHiXjqq9XwNX4Ff94mXH61RFD5dCG",
      type: "tezos",
    },
    carthagenet: {
      host: "https://carthagenet.smartpy.io",
      port: 443,
      network_id: "*",
      type: "tezos",
    },
    mainnet: {
      host: "https://mainnet.smartpy.io",
      port: 443,
      network_id: "*",
      type: "tezos",
    },
    zeronet: {
      host: "https://zeronet.smartpy.io",
      port: 443,
      network_id: "*",
      type: "tezos",
    },
  },
};
