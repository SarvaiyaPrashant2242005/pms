const validateUser = (req, res, next) => {
  const { email, fullname, password } = req.body;

  if (!email || !fullname || !password) {
    return res.status(400).json({ error: 'Email, fullname, and password are required' });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  next();
};

const validateCustomer = (req, res, next) => {
  const { name } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Customer name is required' });
  }

  next();
};

const validateTransaction = (req, res, next) => {
  const { customer_id, transaction_date } = req.body;

  if (!customer_id || !transaction_date) {
    return res.status(400).json({ error: 'Customer ID and transaction date are required' });
  }

  next();
};

module.exports = {
  validateUser,
  validateCustomer,
  validateTransaction
};