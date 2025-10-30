const Clinic = require('../model/clinic');
const Doctor = require('../model/doctors');
const Patient = require('../model/patient');

const patientController = {
  // Create a new patient
  createPatient: async (req, res) => {
    try {
      const { name, gender, contact, dob, age, address, height, weight, photo, doctorId, clinicId } = req.body;

      // Validate required fields
      if (!name || !gender || !contact || !dob || !doctorId || !clinicId) {
        return res.status(400).json({
          success: false,
          message: "Name, gender, contact, dob, doctorId, and clinicId are required"
        });
      }

      // Validate address length if provided
      if (address && address.length > 500) {
        return res.status(400).json({
          success: false,
          message: "Address must not exceed 500 characters"
        });
      }

      // Validate doctor and clinic exist
      const doctor = await Doctor.findByPk(doctorId);
      const clinic = await Clinic.findByPk(clinicId);

      if (!doctor || !clinic) {
        return res.status(404).json({
          success: false,
          message: "Doctor or Clinic not found"
        });
      }

      // Create patient
      const patient = await Patient.create({
        name,
        gender,
        contact,
        dob,
        age,
        address: address || null,
        height,
        weight,
        photo,
        doctorId,
        clinicId
      });

      res.status(201).json({
        success: true,
        message: 'Patient added successfully',
        data: patient
      });
    } catch (err) {
      console.error('Error creating patient:', err);
      res.status(500).json({
        success: false,
        message: "Error while creating patient",
        error: err.message
      });
    }
  },

  // Get all patients by clinic ID
  getPatientByclinicId: async (req, res) => {
    try {
      const { id } = req.params; // clinicId

      const patients = await Patient.findAll({
        where: { clinicId: id },
        include: [
          {
            model: Clinic,
            as: 'clinic',
            attributes: ['id', 'name', 'landlineNo', 'doctorName', 'address']
          },
          {
            model: Doctor,
            as: 'doctor',
            attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
          }
        ],
        order: [['createdAt', 'DESC']] // Most recent first
      });

      res.status(200).json({
        success: true,
        count: patients.length,
        data: patients
      });
    } catch (err) {
      console.error('Error fetching patients:', err);
      res.status(500).json({
        success: false,
        message: 'Error fetching patients',
        error: err.message
      });
    }
  },

  // Get single patient by ID
  getPatientById: async (req, res) => {
    try {
      const { id } = req.params;

      const patient = await Patient.findByPk(id, {
        include: [
          {
            model: Clinic,
            as: 'clinic',
            attributes: ['id', 'name', 'landlineNo', 'doctorName', 'address']
          },
          {
            model: Doctor,
            as: 'doctor',
            attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
          }
        ]
      });

      if (!patient) {
        return res.status(404).json({
          success: false,
          message: "Patient not found"
        });
      }

      res.status(200).json({
        success: true,
        data: patient
      });
    } catch (err) {
      console.error('Error fetching patient:', err);
      res.status(500).json({
        success: false,
        message: "Error fetching patient",
        error: err.message
      });
    }
  },

  // Get all patients by doctor ID
  getPatientsByDoctorId: async (req, res) => {
    try {
      const { doctorId } = req.params;

      const patients = await Patient.findAll({
        where: { doctorId: doctorId },
        include: [
          {
            model: Clinic,
            as: 'clinic',
            attributes: ['id', 'name', 'landlineNo', 'doctorName', 'address']
          },
          {
            model: Doctor,
            as: 'doctor',
            attributes: ['id', 'fullname', 'email', 'degree', 'phoneNo']
          }
        ],
        order: [['createdAt', 'DESC']]
      });

      res.status(200).json({
        success: true,
        count: patients.length,
        data: patients
      });
    } catch (err) {
      console.error('Error fetching patients:', err);
      res.status(500).json({
        success: false,
        message: 'Error fetching patients',
        error: err.message
      });
    }
  },

  // Update patient
  updatePatient: async (req, res) => {
    try {
      const { id } = req.params;
      const { name, gender, contact, dob, age, address, height, weight, photo } = req.body;

      // Validate address length if provided
      if (address && address.length > 500) {
        return res.status(400).json({
          success: false,
          message: "Address must not exceed 500 characters"
        });
      }

      const patient = await Patient.findByPk(id);

      if (!patient) {
        return res.status(404).json({
          success: false,
          message: "Patient not found"
        });
      }

      // Update patient details
      await patient.update({
        name: name || patient.name,
        gender: gender || patient.gender,
        contact: contact !== undefined ? contact : patient.contact,
        dob: dob || patient.dob,
        age: age !== undefined ? age : patient.age,
        address: address !== undefined ? address : patient.address,
        height: height !== undefined ? height : patient.height,
        weight: weight !== undefined ? weight : patient.weight,
        photo: photo !== undefined ? photo : patient.photo
      });

      res.status(200).json({
        success: true,
        message: "Patient updated successfully",
        data: patient
      });
    } catch (err) {
      console.error('Error updating patient:', err);
      res.status(500).json({
        success: false,
        message: "Error updating patient",
        error: err.message
      });
    }
  },

  // Delete patient
  deletePatient: async (req, res) => {
    try {
      const { id } = req.params;

      const patient = await Patient.findByPk(id);

      if (!patient) {
        return res.status(404).json({
          success: false,
          message: "Patient not found"
        });
      }

      await patient.destroy();

      res.status(200).json({
        success: true,
        message: "Patient deleted successfully"
      });
    } catch (err) {
      console.error('Error deleting patient:', err);
      res.status(500).json({
        success: false,
        message: "Error deleting patient",
        error: err.message
      });
    }
  }
};

// Define associations
Doctor.hasMany(Patient, { foreignKey: 'doctorId', as: 'patients' });
Patient.belongsTo(Doctor, { foreignKey: 'doctorId', as: 'doctor' });

Clinic.hasMany(Patient, { foreignKey: 'clinicId', as: 'patients' });
Patient.belongsTo(Clinic, { foreignKey: 'clinicId', as: 'clinic' });

module.exports = patientController;