import {
  loginUser,
  getMe,
  getAllUsers,
  updatePassword,
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
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ error: "Password required" });
    }

    const result = await updatePassword(req.user.id, password);

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
