import {
  loginUser,
  getMe,
  getAllUsers,
  updatePassword,
  createEmployee,
} from "../services/auth.service.js";

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password required" });
    }

    const result = await loginUser(email, password);
    res.json(result);
  } catch (err) {
    res.status(401).json({ error: err.message });
  }
};

export const me = async (req, res) => {
  try {
    const user = await getMe(req.user.id);
    res.json({ user });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
};

export const employees = async (req, res) => {
  try {
    const users = await getAllUsers();
    res.json({ users });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const updatePass = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password required" });
    }

    const result = await updatePassword(email, password);

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const signupEmployee = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      designation,
      location,
      upi_id,
      base_salary,
    } = req.body;

    // Required fields
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ error: "Name, email and password are required" });
    }

    // Basic email format check
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    // Password strength check
    if (password.length < 8) {
      return res
        .status(400)
        .json({ error: "Password must be at least 8 characters" });
    }

    const result = await createEmployee({
      name,
      email,
      password,
      designation,
      location,
      upi_id,
      base_salary,
    });
    res.status(201).json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
