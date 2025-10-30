const express = require('express');
const router = express.Router();
const doctorController = require("../controllers/doctorController");

const {authenticate} = require("../middlewares/auth");
const {validateUser} = require("../middlewares/validator");


router.post("/register", validateUser, doctorController.register);
router.post("/login",  doctorController.login);
router.put('/profile/:id',authenticate, doctorController.updatedoctor);

module.exports = router;