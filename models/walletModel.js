/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
let mongoose = require('mongoose');
let Schema = mongoose.Schema;

// schema for user wallet
let walletSchema = new Schema({
    address:{type:String},
    name:{type:String},
    email:{type:String},
    mobile:{type:String},
    created_at:{type:Date},
    updated_at:{type:Date},
    locks:[]
});

module.exports = mongoose.model('wallet', walletSchema);
