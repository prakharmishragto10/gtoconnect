import express from "express";
import {
  submit,
  myRequests,
  allRequests,
  updateStatus,
} from "../controllers/travel.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/", auth, submit);
router.get("/my", auth, myRequests);
router.get("/all", auth, adminOnly, allRequests);
router.patch("/:id/status", auth, adminOnly, updateStatus);

export default router;
