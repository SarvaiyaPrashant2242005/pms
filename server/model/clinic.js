const {DataTypes} = require('sequelize');
const sequelize = require("../config/db");

const Clinic = sequelize.define('Clinic', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    landlineNo: {
        type: DataTypes.STRING,
        allowNull: true
    },
    doctorName: {
        type: DataTypes.STRING,
        allowNull: false
    },
    address: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    price_per_day : {
        type : DataTypes.STRING,
        allowNull : false
    },
    doctor_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Doctor',
            key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
    }
}, {
    tableName: 'Clinic',
    timestamps: false
});

module.exports = Clinic;