import express from "express";
import {
  generate,
  mySalary,
  myHistory,
  allSalaries,
  markPaid,
  summary,
} from "../controllers/salary.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/generate", auth, adminOnly, generate);
router.get("/my", auth, mySalary);
router.get("/my/history", auth, myHistory);
router.get("/all", auth, adminOnly, allSalaries);
router.get("/summary", auth, adminOnly, summary);
router.patch("/:id/paid", auth, adminOnly, markPaid);

export default router;
