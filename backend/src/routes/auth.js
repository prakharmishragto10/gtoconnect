import express from "express";
import { login, me, employees } from "../controllers/auth.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/login", login);
router.get("/me", auth, me);
router.get("/employees", auth, adminOnly, employees);

export default router;
