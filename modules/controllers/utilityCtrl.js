/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
const config = require('../../config');

let networkId = (req, res) => {
    res.json({networkId: config.networkId, signMessage: config.signMessage});
};

Controller = {
    networkId
};

module.exports = Controller;