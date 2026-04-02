import express from "express";
import {
  login,
  me,
  employees,
  updatePass,
} from "../controllers/auth.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/login", login);
router.get("/me", auth, me);
router.get("/employees", auth, adminOnly, employees);
router.patch("/updatepass", auth, updatePass);

export default router;
