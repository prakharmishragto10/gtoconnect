import express from "express";
import multer from "multer";
import { upload } from "../controllers/upload.controller.js";
import auth from "../middleware/auth.js";

const router = express.Router();

const uploader = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only images allowed"));
    }
  },
});

router.post(
  "/",
  auth,
  (req, res, next) => {
    uploader.single("receipt")(req, res, (err) => {
      if (err) {
        return res.status(400).json({ error: err.message });
      }
      next();
    });
  },
  upload,
);

export default router;
