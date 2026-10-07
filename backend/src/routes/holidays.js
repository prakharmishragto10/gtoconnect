import express from "express";
import { list, create, remove } from "../controllers/holiday.controller.js";
import auth, { adminOnly } from "../middleware/auth.js";

const router = express.Router();

// Everyone signed in can see the holidays; only the admin can change them
router.get("/", auth, list);
router.post("/", auth, adminOnly, create);
router.delete("/:id", auth, adminOnly, remove);

export default router;
