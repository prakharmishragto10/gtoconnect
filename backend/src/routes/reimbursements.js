import express from "express";
import {
  submit,
  myClaims,
  allClaims,
  updateStatus,
  getOne,
  pendingTotal,
} from "../controllers/reimbursement.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/", auth, submit);
router.get("/my", auth, myClaims);
router.get("/all", auth, adminOnly, allClaims);
router.get("/pending-total", auth, adminOnly, pendingTotal);
router.get("/:id", auth, getOne);
router.patch("/:id/status", auth, adminOnly, updateStatus);

export default router;
