const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Prescription = require('./prescription');

const pDose = sequelize.define('pDose', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  pres_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: Prescription,
      key: 'id'
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE'
  },
  days: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  medicine_type: {
    type: DataTypes.ENUM('capsule', 'syrup'),
    allowNull: false,
    defaultValue: 'capsule'
  },
  medicine_name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  time_of_day: {
    type: DataTypes.ENUM('morning', 'afternoon', 'evening'),
    allowNull: false
  },
  meal_time: {
    type: DataTypes.ENUM('before', 'after'),
    allowNull: false
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1 // ✅ fixed: previously `true` (boolean) — incorrect
  }
}, {
  tableName: 'pDose',
  timestamps: true
});


// 🔗 Associations
Prescription.hasMany(pDose, { foreignKey: 'pres_id', as: 'doses' });
pDose.belongsTo(Prescription, { foreignKey: 'pres_id', as: 'prescription' });

module.exports = pDose;
