import express from "express";
import {
  submit,
  myClaims,
  allClaims,
  updateStatus,
  getOne,
  pendingTotal,
  editClaim,
  removeClaim,
} from "../controllers/reimbursement.controller.js";
import auth, { adminOnly, staffOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/", auth, submit);
router.get("/my", auth, myClaims);
router.get("/all", auth, staffOnly, allClaims);
router.get("/pending-total", auth, staffOnly, pendingTotal);
router.get("/:id", auth, getOne);
router.patch("/:id/status", auth, staffOnly, updateStatus);
// Admin only: correct a claim's details, or remove it
router.patch("/:id", auth, adminOnly, editClaim);
router.delete("/:id", auth, adminOnly, removeClaim);

export default router;
