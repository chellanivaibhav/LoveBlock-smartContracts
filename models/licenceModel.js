/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
let mongoose = require('mongoose');
let Schema = mongoose.Schema;

// schema for user wallet
let licenceSchema = new Schema({
    address:{type:String},
    created_at:{type:Date},
    expired_on:{type:Date},
    lockId:{type:String},
    privateImages:[],
    publicImages:[],
    privateLetters:[],
    publicLetters:[],
});

module.exports = mongoose.model('licence', licenceSchema);
