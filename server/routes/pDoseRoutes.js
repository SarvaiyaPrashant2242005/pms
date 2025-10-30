const pDoseController = require("../controllers/pDose");
const router = require("express").Router();

router.post("/" , pDoseController.createDose);

router.get("/:id", pDoseController.getDoseById);

router.get("/" , pDoseController.getAllDoses);

router.put("/:id", pDoseController.updateDose);

router.delete("/:id" , pDoseController.deleteDose);


module.exports = router;