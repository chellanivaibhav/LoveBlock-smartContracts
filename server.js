/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
// BASE SETUP
// =============================================================================
// import the packages we need
const express = require('express');                   //import express module
const bodyParser = require('body-parser');            //import bodyparser
let mongoose = require('mongoose');                 //import mongoose
mongoose.Promise = require('bluebird'); // set Promise provider to bluebird
const app = express();                                //import express contractor
const cors = require('cors');                         //import cors for cross domain requestconst config = require('./config');                   //import config
const config = require('./config');
const morgan = require('morgan');

// configure cors
app.use(cors());

app.use(morgan(':method :url :status :res[content-length] - :response-time ms :date[clf]'));

// configure body parser
app.use(bodyParser.urlencoded({limit: '5mb', extended: true}));
app.use(bodyParser.json({limit: '5mb', extended: true}));
//Mongoose Setup
// =============================================================================
// Connect To Database
mongoose.connect(config.database, function (err) {
    if (err) {
        console.log('Database error: ' + err);
        mongoose.connect(config.database);
    }
});

// On Connection
mongoose.connection.on('connected', () => {
    // console.log('Database connected at ' + config.database);
});

// On Error
mongoose.connection.on('error', (err) =>{
    console.log('Database error: ' + err);
});

// ROUTES FOR OUR API
// =============================================================================
// create our router
const router = express.Router();

// middleware to use for all requests
router.use((req, res, next) => {
    // var ipx = req.headers['x-real-ip'];
    // do logging
    next();
});

// import our routers
// ----------------------------------------------------
let routers = require('./modules/routers');
router.use(routers);
// register our routers
// -------------------------------
app.use('/', router);


// START THE SERVER
// =============================================================================
app.listen(process.env.PORT || config.mainport, (err) => {
    if (err)
    console.log(err);
console.log('Server running at port:' + config.mainport);
});


