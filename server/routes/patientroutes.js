const router = require('express').Router();
const patientController = require("../controllers/patientController");

// Create a new patient
router.post("/", patientController.createPatient);

// Get patients by clinic ID
router.get("/clinic/:id", patientController.getPatientByclinicId);

// Get patients by doctor ID
router.get("/doctor/:doctorId", patientController.getPatientsByDoctorId);

// Get single patient by ID
router.get("/:id", patientController.getPatientById);

// Update patient
router.put("/:id", patientController.updatePatient);

// Delete patient
router.delete("/:id", patientController.deletePatient);

module.exports = router;