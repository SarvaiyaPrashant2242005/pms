const {DataTypes} = require("sequelize");
const sequelize = require("../config/db");

const Doctor = require("./doctors");
const Clinic = require("./clinic");


const Patient = sequelize.define('Patient' , {
    id : {
        type : DataTypes.INTEGER,
        primaryKey : true,
        autoIncrement : true
    },
    name : {
        type : DataTypes.STRING,
        allowNull : false
    },
    gender : {
        type : DataTypes.STRING,
        allowNull : false
    },
    contact : {
        type : DataTypes.STRING,
        allowNull : false
    },
    dob : {
        type : DataTypes.DATE,
        allowNull : false
    },
    age : {
        type : DataTypes.INTEGER,
        allowNull : false
    },
    address : {
        type : DataTypes.TEXT,
        allowNull : true
    },
    height : {
        type : DataTypes.DECIMAL,
        allowNull : true
    },
    weight : {
        type:  DataTypes.DECIMAL,
        allowNull : true
    },
    photo : {
        type : DataTypes.STRING,
        allowNull : true
    },
    doctorId : {
        type : DataTypes.INTEGER,
        allowNull : false,
        references : {
            model : Doctor,
            key : 'id'
        },
        onUpdate : 'CASCADE',
        onDelete : 'CASCADE'
    },
    clinicId : {
        type : DataTypes.INTEGER,
        allowNull : false,
        references : {
            model : Clinic,
            key : 'id'
        },
        onUpdate : 'CASCADE',
        onDelete : 'CASCADE'
    }
    
}, {
    tableName : 'patients',
    timestamps : true,
})

// name, dob / age, gender, address, height, mobilenumber, weight, photo
Doctor.hasMany(Patient, { foreignKey: 'doctorId' });
Patient.belongsTo(Doctor, { foreignKey: 'doctorId' });

Clinic.hasMany(Patient, { foreignKey: 'clinicId' });
Patient.belongsTo(Clinic, { foreignKey: 'clinicId' });

module.exports = Patient;