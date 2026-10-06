import express from "express";
import {
  login,
  me,
  employees,
  updatePass,
  signupEmployee,
  removeEmployee,
  editEmployee,
} from "../controllers/auth.controller.js";
import auth, { adminOnly, staffOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/login", login);
router.get("/me", auth, me);
router.get("/employees", auth, staffOnly, employees);

router.patch("/updatepass", auth, adminOnly, updatePass);
router.post("/signup", auth, adminOnly, signupEmployee);
router.delete("/employees/:userId", auth, adminOnly, removeEmployee);
router.patch("/employees/:userId", auth, adminOnly, editEmployee);

export default router;
