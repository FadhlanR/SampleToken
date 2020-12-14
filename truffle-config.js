var PrivateKeyProvider = require("truffle-privatekey-provider");
require('dotenv').config()

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 10000000000,
      network_id: '*',
    },
    ropsten: {
      network_id: 3,
      gas: 5000000,
      gasPrice: 10000000000,
      provider: new PrivateKeyProvider(process.env.ADMIN_PRIVATE_KEY, process.env.ROPSTEN_URL)
    }
  }, 
  compilers: {
    solc: {
      version: "0.6.3",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
}
