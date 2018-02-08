/**
 * Created by Tauseef Naqvi on 8-02-2018.
 */
let mongoose = require('mongoose');
let Schema = mongoose.Schema;

// schema for user wallet
let lockSchema = new Schema({
    lockId: {type: String},
    created_at: {type: Date},
    owner:{type:String},
    isLocked: {type: Boolean}, //Love lock in locked on blockchain
    licenceId:{type:String},
    isOnSale: {type: Boolean}, //Love lock for sale on blockchain
    isOnRent: {type: Boolean}, //Love lock for rent on blockchain
    lockImagePath:{type:String},
    lockColors:[]
    history:{
        previousOwners:[],
    }
});

module.exports = mongoose.model('lock', lockSchema);
