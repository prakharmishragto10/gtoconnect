import express from "express";
import multer from "multer";
import { upload } from "../controllers/upload.controller.js";
import auth from "../middleware/auth.js";

const router = express.Router();

const uploader = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    // An explicit list: "image/*" would also admit SVG, which can carry
    // scripts and is served from a public bucket.
    const allowed = ["image/jpeg", "image/png", "image/webp"];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Only JPG, PNG or WEBP images allowed"));
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
