var PrivateKeyProvider = require("truffle-privatekey-provider")
require('dotenv').config()

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 10000000000,
      networkId: '*',
    },
    ropsten: {
      network_id: 3,
      gas: 5000000,
      gasPrice: 10000000000,
      provider: new PrivateKeyProvider(process.env.ADMIN_PRIVATE_KEY, process.env.ROPSTEN_URL)
    },
    mainnet: {
      network_id: 1,
      gas: 4600000,
      gasPrice: 130000000000,
      provider: new PrivateKeyProvider(process.env.ADMIN_PRIVATE_KEY, process.env.MAINNET_URL)
    },
  },
};
