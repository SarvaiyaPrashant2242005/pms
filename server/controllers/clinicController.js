const Clinic = require('../model/clinic');
const Doctor = require('../model/doctors');

const clinicController = {
  // Create a new clinic
  createClinic: async (req, res) => {
    try {
      const { name, landlineNo, doctorName, address, price_per_day, doctor_id } = req.body;

      // Validate required fields
      if (!name || !doctorName || !doctor_id) {
        return res.status(400).json({
          success: false,
          message: 'Name, doctorName, and doctor_id are required'
        });
      }

      // Check if doctor exists
      const doctor = await Doctor.findByPk(doctor_id);
      if (!doctor) {
        return res.status(404).json({
          success: false,
          message: 'Doctor not found'
        });
      }

      // Create clinic
      const clinic = await Clinic.create({
        name,
        landlineNo,
        doctorName,
        address,
        price_per_day,
        doctor_id
      });

      res.status(201).json({
        success: true,
        message: 'Clinic created successfully',
        data: clinic
      });
    } catch (error) {
      console.error('Error creating clinic:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating clinic',
        error: error.message
      });
    }
  },

  // Get all clinics
  getAllClinics: async (req, res) => {
    try {
      const clinics = await Clinic.findAll({
        include: [{
          model: Doctor,
          as: 'doctor',
          attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
        }]
      });

      res.status(200).json({
        success: true,
        count: clinics.length,
        data: clinics
      });
    } catch (error) {
      console.error('Error fetching clinics:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching clinics',
        error: error.message
      });
    }
  },

  // Get clinic by ID
  getClinicById: async (req, res) => {
    try {
      const { id } = req.params;

      const clinic = await Clinic.findByPk(id, {
        include: [{
          model: Doctor,
          as: 'doctor',
          attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
        }]
      });

      if (!clinic) {
        return res.status(404).json({
          success: false,
          message: 'Clinic not found'
        });
      }

      res.status(200).json({
        success: true,
        data: clinic
      });
    } catch (error) {
      console.error('Error fetching clinic:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching clinic',
        error: error.message
      });
    }
  },

  // Get clinics by doctor ID
  getClinicsByDoctorId: async (req, res) => {
    try {
      const { doctorId } = req.params;

      const clinics = await Clinic.findAll({
        where: { doctor_id: doctorId },
        include: [{
          model: Doctor,
          as: 'doctor',
          attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
        }]
      });

      res.status(200).json({
        success: true,
        count: clinics.length,
        data: clinics
      });
    } catch (error) {
      console.error('Error fetching clinics:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching clinics',
        error: error.message
      });
    }
  },

  // Update clinic
  updateClinic: async (req, res) => {
    try {
      const { id } = req.params;
      const { name, landlineNo, doctorName, address, price_per_day, doctor_id } = req.body;

      const clinic = await Clinic.findByPk(id);
      if (!clinic) {
        return res.status(404).json({
          success: false,
          message: 'Clinic not found'
        });
      }

      // Verify doctor if changed
      if (doctor_id && doctor_id !== clinic.doctor_id) {
        const doctor = await Doctor.findByPk(doctor_id);
        if (!doctor) {
          return res.status(404).json({
            success: false,
            message: 'Doctor not found'
          });
        }
      }

      // Update clinic details
      await clinic.update({
        name: name || clinic.name,
        landlineNo: landlineNo !== undefined ? landlineNo : clinic.landlineNo,
        doctorName: doctorName || clinic.doctorName,
        address: address !== undefined ? address : clinic.address,
        price_per_day: price_per_day !== undefined ? price_per_day : clinic.price_per_day,
        doctor_id: doctor_id || clinic.doctor_id
      });

      res.status(200).json({
        success: true,
        message: 'Clinic updated successfully',
        data: clinic
      });
    } catch (error) {
      console.error('Error updating clinic:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating clinic',
        error: error.message
      });
    }
  },

  // Delete clinic
  deleteClinic: async (req, res) => {
    try {
      const { id } = req.params;

      const clinic = await Clinic.findByPk(id);
      if (!clinic) {
        return res.status(404).json({
          success: false,
          message: 'Clinic not found'
        });
      }

      await clinic.destroy();

      res.status(200).json({
        success: true,
        message: 'Clinic deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting clinic:', error);
      res.status(500).json({
        success: false,
        message: 'Error deleting clinic',
        error: error.message
      });
    }
  }
};

// Associations
Doctor.hasMany(Clinic, { foreignKey: 'doctor_id', as: 'clinics' });
Clinic.belongsTo(Doctor, { foreignKey: 'doctor_id', as: 'doctor' });

module.exports = clinicController;
