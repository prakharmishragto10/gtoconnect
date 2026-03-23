import { uploadReceipt } from "../services/upload.service.js";

export const upload = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file provided" });
    }

    const url = await uploadReceipt(
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
    );

    res.json({ url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
