/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
const config = require('../../config');
const jwt = require('jsonwebtoken');
const ethers = require('ethers');
const utils = ethers.utils;
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider(config.rpcUrl));

//
let sign = (req, res) => {
    let address = req.body.address;
    let signHash = req.body.sign;

    if (!address)
        return res.json({success: false, msg: "Address can't be null."});
    if (!signHash)
        return res.json({success: false, msg: "Sign hash can't be null."});

    /*try {
        address = utils.getAddress(address);
    } catch (error) {
        return res.json({success: false, msg: "Address is not valid.", error: error});
    }*/

    web3.eth.personal.ecRecover(config.signMessage, signHash)
        .then((signerAddress) => {

            if (signerAddress.toLowerCase() === address.toLowerCase()) {
                let token = jwt.sign({address: address}, config.secret);
                return res.json({success: true, token: token})
            }
            res.status(401).json({success: false, msg: "unauthorized request"});
        })
        .catch((error) => {
            res.json({success: false, msg: "there is an error", error: error.message})
        });

};

let getUserProfile = (req,res) =>{
    console.log(req.body.address);
    res.json("success");
};
let updateUserProfile = (req,res) =>{
    console.log(req.body.address);
    res.json("success");
};

Controller = {
    sign,
    getUserProfile,
    updateUserProfile
};

module.exports = Controller;