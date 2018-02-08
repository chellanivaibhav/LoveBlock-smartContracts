/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */

const config = require('./config');
let web3 = require('web3');
web3 = new web3(new web3.providers.HttpProvider(config.rpcUrl));
const async = require('async');
const ethers = require('ethers');
const utils = ethers.utils;