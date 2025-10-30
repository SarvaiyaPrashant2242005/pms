const Doctor = require("../model/doctors");
const jwt = require("jsonwebtoken");

const doctorController = {
    register: async (req, res) => {
        try {
            console.log('=== REGISTRATION REQUEST ===');
            console.log('Request body:', req.body);
            
            const { fullname, email, degree, password, phoneNo } = req.body;

            // Validate required fields
            if (!fullname || !email || !password) {
                return res.status(400).json({ 
                    message: 'Missing required fields: fullname, email, password' 
                });
            }

            console.log('Creating doctor with data:', { 
                fullname, 
                email, 
                degree, 
                phoneNo,
                passwordLength: password?.length 
            });

            const doctor = await Doctor.create({
                fullname,
                email,
                degree,
                password,
                phoneNo
            });

            console.log('Doctor created successfully!');
            console.log('Doctor ID:', doctor.id);
            console.log('Doctor data:', doctor.toJSON());

            // Verify the record was actually saved
            const savedDoctor = await Doctor.findByPk(doctor.id);
            console.log('Verification - Doctor found in DB:', savedDoctor ? 'YES' : 'NO');

            res.status(201).json({
                message: "Doctor Register Successfully",
                doctorId: doctor.id
            });
        } catch (err) {
            console.error('=== REGISTRATION ERROR ===');
            console.error('Error name:', err.name);
            console.error('Error message:', err.message);
            console.error('Full error:', err);
            
            if (err.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: 'Email already exists' });
            }
            if (err.name === 'SequelizeValidationError') {
                return res.status(400).json({ 
                    message: 'Validation error', 
                    errors: err.errors.map(e => e.message) 
                });
            }
            res.status(500).json({ 
                message: 'Registration failed', 
                error: err.message 
            });
        }
    },

    login: async (req, res) => {
        try {
            console.log('=== LOGIN REQUEST ===');
            console.log('Email:', req.body.email);
            
            const { email, password } = req.body;
            const doctor = await Doctor.findOne({ where: { email } });

            if (!doctor) {
                console.log('Doctor not found');
                return res.status(401).json({ message: "Invalid credentials" });
            }

            console.log('Doctor found:', doctor.id);
            const isValidPassword = await doctor.validatePassword(password);
            console.log('Password valid:', isValidPassword);

            if (!isValidPassword) {
                return res.status(401).json({ message: "Invalid credentials" });
            }

            const token = jwt.sign(
                {
                    id: doctor.id,
                    email: doctor.email
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            console.log('Login successful, sending response');
            res.json({
                message: "Doctor Logged in",
                token,
                doctor: {
                    id: doctor.id,
                    email: doctor.email,
                    fullname: doctor.fullname,
                    degree: doctor.degree,
                    phoneNo: doctor.phoneNo
                }
            });
        } catch (err) {
            console.error('=== LOGIN ERROR ===');
            console.error(err);
            res.status(500).json({ message: 'Login failed', error: err.message });
        }
    },

    updatedoctor: async (req, res) => {
        try {
            const { id } = req.params;
            const { degree, phoneNo, fullname } = req.body;
            
            const doctor = await Doctor.findByPk(id);
            if (!doctor) {
                return res.status(404).json({ message: "Doctor not found" });
            }
            
            const updateData = {};
            if (fullname) updateData.fullname = fullname;
            if (degree) updateData.degree = degree;
            if (phoneNo) updateData.phoneNo = phoneNo;
            
            await Doctor.update(updateData, { where: { id } });
            
            res.json({ message: "Profile Updated Successfully!!!" });
        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Update failed', error: err.message });
        }
    }
};

module.exports = doctorController;