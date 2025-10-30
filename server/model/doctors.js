const {DataTypes} = require('sequelize');
const sequelize = require("../config/db");
const bcrypt = require("bcrypt");

const Doctor = sequelize.define('Doctor', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true
        }
    },
    fullname: {
        type: DataTypes.STRING,
        allowNull: false
    },
    degree: {
        type: DataTypes.STRING,
        allowNull: true
    },
    phoneNo: {
        type: DataTypes.STRING,
        allowNull: true
    },
    password: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    tableName: 'Doctor',
    timestamps: false,
    hooks: {
        beforeCreate: async (doctor) => {
            try {
                if (doctor.password) {
                    console.log('Hashing password in beforeCreate hook');
                    const salt = await bcrypt.genSalt(10);
                    doctor.password = await bcrypt.hash(doctor.password, salt);
                    console.log('Password hashed successfully');
                }
            } catch (error) {
                console.error('Error in beforeCreate hook:', error);
                throw error; // Re-throw to prevent creation
            }
        },
        beforeUpdate: async (doctor) => {
            try {
                if (doctor.changed('password')) {
                    console.log('Hashing password in beforeUpdate hook');
                    const salt = await bcrypt.genSalt(10);
                    doctor.password = await bcrypt.hash(doctor.password, salt);
                    console.log('Password updated successfully');
                }
            } catch (error) {
                console.error('Error in beforeUpdate hook:', error);
                throw error;
            }
        }
    }
});

Doctor.prototype.validatePassword = async function(password) {
    return await bcrypt.compare(password, this.password);
};

module.exports = Doctor;