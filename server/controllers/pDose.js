const Prescription = require("../model/prescription");
const pDose = require("../model/PrescriptionDose");

const pDoseController = {
    // 🟢 Create Dose
    createDose: async (req, res) => {
        try {
            const { pres_id, days, medicine_type, medicine_name, time_of_day, meal_time, quantity } = req.body;

            // Check if prescription exists
            const prescription = await Prescription.findByPk(pres_id);
            if (!prescription) {
                return res.status(404).json({ message: "Prescription not found" });
            }

            const dose = await pDose.create({
                pres_id,
                days,
                medicine_type,
                medicine_name,
                time_of_day,
                meal_time,
                quantity
            });

            res.status(201).json({
                message: "Dose created successfully",
                data: dose
            });
        } catch (error) {
            console.error("Error creating dose:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟡 Get All Doses
    getAllDoses: async (req, res) => {
        try {
            const doses = await pDose.findAll({
                include: [
                    {
                        model: Prescription,
                        as: "prescription",
                        attributes: ["id", "date", "dieases", "symptoms"]
                    }
                ],
                order: [["createdAt", "DESC"]]
            });

            res.status(200).json(doses);
        } catch (error) {
            console.error("Error fetching doses:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟢 Get Dose by ID
    getDoseById: async (req, res) => {
        try {
            const { id } = req.params;

            const dose = await pDose.findByPk(id, {
                include: [
                    {
                        model: Prescription,
                        as: "prescription",
                        attributes: ["id", "date", "dieases", "symptoms"]
                    }
                ]
            });

            if (!dose) {
                return res.status(404).json({ message: "Dose not found" });
            }

            res.status(200).json(dose);
        } catch (error) {
            console.error("Error fetching dose:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟠 Update Dose
    updateDose: async (req, res) => {
        try {
            const { id } = req.params;
            const { days, medicine_type, medicine_name, time_of_day, meal_time, quantity } = req.body;

            const dose = await pDose.findByPk(id);
            if (!dose) {
                return res.status(404).json({ message: "Dose not found" });
            }

            await dose.update({
                days,
                medicine_type,
                medicine_name,
                time_of_day,
                meal_time,
                quantity
            });

            res.status(200).json({
                message: "Dose updated successfully",
                data: dose
            });
        } catch (error) {
            console.error("Error updating dose:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🔴 Delete Dose
    deleteDose: async (req, res) => {
        try {
            const { id } = req.params;

            const dose = await pDose.findByPk(id);
            if (!dose) {
                return res.status(404).json({ message: "Dose not found" });
            }

            await dose.destroy();

            res.status(200).json({ message: "Dose deleted successfully" });
        } catch (error) {
            console.error("Error deleting dose:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    },

    // 🟣 Get Doses by Prescription ID
    getDosesByPrescription: async (req, res) => {
        try {
            const { pres_id } = req.params;

            const doses = await pDose.findAll({
                where: { pres_id },
                order: [["createdAt", "ASC"]]
            });

            if (doses.length === 0) {
                return res.status(404).json({ message: "No doses found for this prescription" });
            }

            res.status(200).json(doses);
        } catch (error) {
            console.error("Error fetching doses by prescription:", error);
            res.status(500).json({ message: "Internal server error", error });
        }
    }
};

module.exports = pDoseController;
 