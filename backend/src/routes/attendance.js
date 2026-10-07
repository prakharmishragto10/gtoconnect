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
  myCalendar,
  employeeCalendar,
  markEmployeePresent,
} from "../controllers/attendance.controller.js";
import auth, { adminOnly, staffOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/checkin", auth, checkin);
router.post("/checkout", auth, checkout);
router.get("/today", auth, today);
router.get("/my", auth, myHistory);
router.get("/my/calendar", auth, myCalendar);
router.get("/all", auth, staffOnly, allToday);
router.get("/report", auth, staffOnly, monthlyReport);
router.get("/all-history", auth, staffOnly, allHistory);
router.get("/employee/:userId", auth, staffOnly, employeeHistory);
router.get("/employee/:userId/calendar", auth, staffOnly, employeeCalendar);
// Admin override: mark any employee present on any past date or today
router.post("/mark-present", auth, adminOnly, markEmployeePresent);

export default router;
