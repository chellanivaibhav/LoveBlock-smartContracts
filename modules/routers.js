/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */

const express = require("express");
const router = express.Router();
const config = require('../config');
const ClientError = require('../errors/clienterror');
const jwt = require('jsonwebtoken');
const walletCtrl = require('./controllers/walletCtrl');
const utilityCtrl = require('./controllers/utilityCtrl');


function getCredentials(req) {
    let identity = req.header('Authorization');
    if (!identity) return;

    return {
        auth: identity,
    };
}

function getServerWithAuth(req, res, cb) {
    let credentials = getCredentials(req);
    if (!credentials)
        return returnError(new ClientError({
            code: 'NOT_AUTHORIZED'
        }), res, req);

    let token = credentials.auth;
    jwt.verify(token, config.secret, function (err, decoded) {
        if (err)
            return returnError(new ClientError({
                code: 'NOT_AUTHORIZED'
            }), res, req);

        cb(decoded)
    })

}

function returnError(err, res, req) {
    if (err instanceof ClientError) {

        let status = (err.code == 'NOT_AUTHORIZED') ? 401 : 400;

        res.status(status).json({
            code: err.code,
            message: err.message,
        }).end();
    } else {
        let code = 500,
            message;
        if (_.isObject(err)) {
            code = err.code || err.statusCode;
            message = err.message || err.body;
        }

        let m = message || err.toString();

        if (!opts.disableLogs)
            log.error(req.url + ' :' + code + ':' + m);

        res.status(code || 500).json({
            error: m,
        }).end();
    }
}

//GET request for current network id on server (1 for livenet and 3 for testnet)
router.route('^/network-sign$').get(utilityCtrl.networkId);

//POST request to get jwt token for further authentication request
router.route('^/sign$').post(walletCtrl.sign);


//POST request to update or new  user profile
router.route('^/user/me$').post(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});

//GET request for user profile
router.route('^/user/me$').get(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.getUserProfile(req, res);
    })
});


//POST request to upload user photos with lockid against licence of lock
router.route('^/user/photos$').post(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});

//GET request to get user photos with lockid against licence of lock, according authentication
router.route('^/user/photos/:lockId$').get(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});

//POST request to upload user letters with lockid against licence of lock
router.route('^/user/letters$').get(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});

//GET request to get user letters with lockid against licence of lock, according authentication
router.route('^/user/letters/:lockId$').get(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});

//GET request to get details for lock according authentication
router.route('^/lock/:lockId$').get(function (req, res) {
    getServerWithAuth(req, res, function (decode) {
        req.body.address = decode.address;
        walletCtrl.updateUserProfile(req, res);
    })
});


module.exports = router;
