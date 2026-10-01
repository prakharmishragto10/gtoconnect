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
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/login", login);
router.get("/me", auth, me);
router.get("/employees", auth, adminOnly, employees);

router.patch("/updatepass", updatePass);
router.post("/signup", signupEmployee);
router.delete("/employees/:userId", auth, adminOnly, removeEmployee);
router.patch("/employees/:userId", auth, adminOnly, editEmployee);

export default router;
