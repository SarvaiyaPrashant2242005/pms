const express = require('express');
const router = express.Router();
const clinicController = require('../controllers/clinicController');

// Create a new clinic
router.post('/', clinicController.createClinic);

// Get all clinics
router.get('/', clinicController.getAllClinics);

// Get clinics by doctor ID (place before '/:id' to avoid shadowing)
router.get('/doctors/:doctorId', clinicController.getClinicsByDoctorId);

// Get clinic by ID
router.get('/:id', clinicController.getClinicById);

// Update clinic
router.put('/:id', clinicController.updateClinic);

// Delete clinic
router.delete('/:id', clinicController.deleteClinic);

module.exports = router;