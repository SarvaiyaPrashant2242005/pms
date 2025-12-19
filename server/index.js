const express = require('express');
const cors = require('cors');
require('dotenv').config();
const sequelize = require("./config/db");

const app = express();
const PORT = process.env.PORT || 3000;

const doctorRoutes = require("./routes/doctorRoutes");
const clinicRoutes = require("./routes/clinicRoutes");
const patientRoutes = require("./routes/patientroutes");
const prescriptionRoutes = require("./routes/prescriptionRoutes");
const pDose = require("./routes/pDoseRoutes");

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended : true}));


// Health check
app.get('/test', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running', server : "medtrack" });
});



app.use("/doctor",doctorRoutes);
app.use("/clinics" , clinicRoutes);
app.use("/patient", patientRoutes);
app.use('/prescriptions' , prescriptionRoutes);
app.use('/pdose', pDose);

sequelize.authenticate()
.then(() => {
    console.log('DATABASE CONNECTED');
    return sequelize.sync({alter : true});
})
.then(()=>{
    app.listen(PORT, () => {
        console.log(`🚀 Server is running on port ${PORT}`); 
    });
})
  .catch(err => {
    console.error('❌ Unable to connect to database:', err);
    process.exit(1);
  });

