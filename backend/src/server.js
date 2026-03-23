import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import authRoutes from "./routes/auth.js";
import attendanceRoutes from "./routes/attendance.js";
import locationRoutes from "./routes/location.js";
import reimbursementRoutes from "./routes/reimbursements.js";
import salaryRoutes from "./routes/salary.js";
import paymentRoutes from "./routes/payments.js";
import uploadRoutes from "./routes/upload.js";

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/location", locationRoutes);
app.use("/api/reimbursements", reimbursementRoutes);
app.use("/api/salary", salaryRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/upload", uploadRoutes);

app.get("/", (req, res) => {
  res.json({ message: "GTO API is running", version: "1.0.0" });
});

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`GTO Server running on http://localhost:${PORT}`);
});
