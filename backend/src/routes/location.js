import express from "express";
import {
  update,
  myLocation,
  allLive,
  history,
} from "../controllers/location.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

router.post("/update", auth, update);
router.get("/me", auth, myLocation);
router.get("/all", auth, adminOnly, allLive);
router.get("/history/:userId", auth, adminOnly, history);

export default router;
