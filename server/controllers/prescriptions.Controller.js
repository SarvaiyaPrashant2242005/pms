const Prescription = require("../model/prescription");
const pDose = require("../model/PrescriptionDose");
const Patient = require("../model/patient");

const prescriptionController = {
    // 🟢 Create Prescription
    createPrescription: async (req, res) => {
        try {
            const { patient_id, date, dieases, symptoms, payment_mode, payment_amount, paid_amount } = req.body;

            // Validate patient existence
            const patient = await Patient.findByPk(patient_id);
            if (!patient) {
                return res.status(404).json({ message: "Patient not found" });
            }

            const prescription = await Prescription.create({
                patient_id,
                date,
                dieases,
                symptoms,
                payment_mode,
                payment_amount,
                paid_amount
            });

            res.status(201).json({
                message: "Prescription created successfully",
                data: prescription
            });
        } catch (error) {
            console.error("Error creating prescription:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟡 Get All Prescriptions
    getAllPrescriptions: async (req, res) => {
        try {
            const prescriptions = await Prescription.findAll({
                include: [
                    {
                        model: Patient,
                        attributes: ["id", "name", "age", "gender", "phone"]
                    }
                ],
                order: [["createdAt", "DESC"]]
            });

            res.status(200).json(prescriptions);
        } catch (error) {
            console.error("Error fetching prescriptions:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟢 Get Prescription by ID
    getPrescriptionById: async (req, res) => {
        try {
            const { id } = req.params;

            const prescription = await Prescription.findByPk(id, {
                include: [
                    {
                        model: Patient,
                        attributes: ["id", "name", "age", "gender", "phone"]
                    }
                ]
            });

            if (!prescription) {
                return res.status(404).json({ message: "Prescription not found" });
            }

            res.status(200).json(prescription);
        } catch (error) {
            console.error("Error fetching prescription:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // Get Prescription(s) by Patient ID
    getPrescriptionByPatientId: async (req, res) => {
        try {
            const { patient_id } = req.params;

            const patient = await Patient.findByPk(patient_id);
            if (!patient) {
                return res.status(404).json({ message: "Patient not found" });
            }

            const prescriptions = await Prescription.findAll({
                where: { patient_id },
                include: [
                    {
                        model: Patient,
                        attributes: ["id", "name", "age", "gender", "phone"]
                    }
                ],
                order: [["createdAt", "DESC"]]
            });

            if (prescriptions.length === 0) {
                return res.status(404).json({ message: "No prescriptions found for this patient" });
            }

            res.status(200).json({
                message: "Prescriptions fetched successfully",
                data: prescriptions
            });
        } catch (error) {
            console.error("Error fetching prescriptions by patient ID:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟣 Get Prescriptions with Doses by Patient ID
    getDosesByPatientId: async (req, res) => {
        try {
            const { patientId } = req.params;

            const patient = await Patient.findByPk(patientId);
            if (!patient) {
                return res.status(404).json({ message: "Patient not found" });
            }

            const prescriptions = await Prescription.findAll({
                where: { patient_id: patientId },
                include: [
                    {
                        model: pDose,
                        as: 'doses',
                        attributes: ['id', 'medicine_name', 'time_of_day', 'meal_time']
                    }
                ],
                order: [["createdAt", "DESC"]]
            });

            if (!prescriptions || prescriptions.length === 0) {
                return res.status(404).json({ message: "No prescriptions found for this patient" });
            }

            const formatted = prescriptions.map(p => ({
                id: p.id,
                disease: p.dieases,
                date: p.date,
                symptoms: p.symptoms,
                payment_mode: p.payment_mode,
                payment_amount: p.payment_amount,
                paid_amount: p.paid_amount,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
                doses: (p.doses || []).map(d => ({
                    id: d.id,
                    medicine_name: d.medicine_name,
                    time_of_day: d.time_of_day,
                    meal_time: d.meal_time
                }))
            }));

            return res.status(200).json({
                success: true,
                patientId: Number(patientId),
                prescriptions: formatted
            });
        } catch (error) {
            console.error("Error fetching doses by patient ID:", error);
            return res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟠 Update Prescription
    updatePrescription: async (req, res) => {
        try {
            const { id } = req.params;
            const { date, dieases, symptoms, payment_mode, payment_amount, paid_amount } = req.body;

            const prescription = await Prescription.findByPk(id);
            if (!prescription) {
                return res.status(404).json({ message: "Prescription not found" });
            }

            await prescription.update({ date, dieases, symptoms, payment_mode, payment_amount, paid_amount });

            res.status(200).json({
                message: "Prescription updated successfully",
                data: prescription
            });
        } catch (error) {
            console.error("Error updating prescription:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🔴 Delete Prescription
    deletePrescription: async (req, res) => {
        try {
            const { id } = req.params;

            const prescription = await Prescription.findByPk(id);
            if (!prescription) {
                return res.status(404).json({ message: "Prescription not found" });
            }

            await prescription.destroy();

            res.status(200).json({ message: "Prescription deleted successfully" });
        } catch (error) {
            console.error("Error deleting prescription:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    }
};

module.exports = prescriptionController;
