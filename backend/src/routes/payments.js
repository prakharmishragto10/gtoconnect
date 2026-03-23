import express from "express";
import {
  record,
  myHistory,
  allPayments,
} from "../controllers/payment.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/", auth, adminOnly, record);
router.get("/my", auth, myHistory);
router.get("/all", auth, adminOnly, allPayments);

export default router;
