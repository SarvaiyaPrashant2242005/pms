const router = require("express").Router();
const prescriptionController = require("../controllers/prescriptions.Controller");


router.post("/" , prescriptionController.createPrescription);

router.get("/" , prescriptionController.getAllPrescriptions);

// Get prescriptions with doses by patient id
router.get("/patient/:patientId", prescriptionController.getDosesByPatientId);

router.get("/:id", prescriptionController.getPrescriptionById);

router.get("/patientprescription/:id", prescriptionController.getPrescriptionByPatientId);

router.put("/:id", prescriptionController.updatePrescription);

router.delete("/:id", prescriptionController.deletePrescription);

module.exports = router;