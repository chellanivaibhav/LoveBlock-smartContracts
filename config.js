/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
const config = {
    'mainport': 3003,                                         // set ourport
    'eventwatcherport': 3004,                                         // set ourport
    'signMessage':'Lovelock',                   // decode  address with this msg
    'secret':'kjhguhgftydgvhgvdft',             // sign jwt token with this secret
    'networkId':3, // 1 for livenet 3 for testnet
    'database': 'mongodb://testuser:testpassword@aws-ap-southeast-1-portal.2.dblayer.com:16478/loveblock-test',          // database connection link
    'rpcUrl':'http://13.250.15.1:8545' //rpcUrl of geth node
};
module.exports = config;