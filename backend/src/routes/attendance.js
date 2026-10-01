import express from "express";
import {
  checkin,
  checkout,
  today,
  myHistory,
  allToday,
  monthlyReport,
  allHistory,
  employeeHistory,
} from "../controllers/attendance.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/checkin", auth, checkin);
router.post("/checkout", auth, checkout);
router.get("/today", auth, today);
router.get("/my", auth, myHistory);
router.get("/all", auth, adminOnly, allToday);
router.get("/report", auth, adminOnly, monthlyReport);
router.get("/all-history", auth, adminOnly, allHistory);
router.get("/employee/:userId", auth, adminOnly, employeeHistory);

export default router;
