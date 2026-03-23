import express from "express";
import {
  checkin,
  checkout,
  today,
  myHistory,
  allToday,
  monthlyReport,
} from "../controllers/attendance.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/checkin", auth, checkin);
router.post("/checkout", auth, checkout);
router.get("/today", auth, today);
router.get("/my", auth, myHistory);
router.get("/all", auth, adminOnly, allToday);
router.get("/report", auth, adminOnly, monthlyReport);

export default router;
