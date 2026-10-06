import express from "express";
import multer from "multer";
import {
  generate,
  mySalary,
  myHistory,
  allSalaries,
  markPaid,
  summary,
  uploadSlip,
  slipUrl,
} from "../controllers/salary.controller.js";
import auth, { staffOnly } from "../middleware/auth.js";

const router = express.Router();

const slipUploader = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 4 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ["application/pdf", "image/jpeg", "image/png"];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Salary slip must be a PDF, JPG or PNG"));
    }
  },
});

router.post("/generate", auth, staffOnly, generate);
router.get("/my", auth, mySalary);
router.get("/my/history", auth, myHistory);
router.get("/all", auth, staffOnly, allSalaries);
router.get("/summary", auth, staffOnly, summary);
router.patch("/:id/paid", auth, staffOnly, markPaid);

// Salary slip: staff upload, staff or the slip's owner can open it
router.post(
  "/:id/slip",
  auth,
  staffOnly,
  (req, res, next) => {
    slipUploader.single("slip")(req, res, (err) => {
      if (err) {
        const message =
          err.code === "LIMIT_FILE_SIZE" ? "Salary slip must be under 4 MB" : err.message;
        return res.status(400).json({ error: message });
      }
      next();
    });
  },
  uploadSlip,
);
router.get("/:id/slip", auth, slipUrl);

export default router;
