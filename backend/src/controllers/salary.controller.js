import {
  generateMonthlySalary,
  getMySalary,
  getMySalaryHistory,
  getAllSalaries,
  markSalaryPaid,
  getPayrollSummary,
  uploadSalarySlip,
  getSalarySlipUrl,
} from "../services/salary.service.js";

export const generate = async (req, res) => {
  try {
    const { month, year } = req.body;
    if (!month || !year) {
      return res.status(400).json({ error: "month and year required" });
    }
    const data = await generateMonthlySalary(month, year);
    res.json({ message: "Salary generated", salaries: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const mySalary = async (req, res) => {
  try {
    const { month, year } = req.query;
    if (!month || !year) {
      return res.status(400).json({ error: "month and year required" });
    }
    const data = await getMySalary(req.user.id, month, year);
    res.json({ salary: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const myHistory = async (req, res) => {
  try {
    const data = await getMySalaryHistory(req.user.id);
    res.json({ salaries: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allSalaries = async (req, res) => {
  try {
    const { month, year } = req.query;
    if (!month || !year) {
      return res.status(400).json({ error: "month and year required" });
    }
    const data = await getAllSalaries(month, year);
    res.json({ salaries: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const markPaid = async (req, res) => {
  try {
    const data = await markSalaryPaid(req.params.id);
    res.json({ message: "Salary marked as paid", salary: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const summary = async (req, res) => {
  try {
    const { month, year } = req.query;
    if (!month || !year) {
      return res.status(400).json({ error: "month and year required" });
    }
    const data = await getPayrollSummary(month, year);
    res.json({ summary: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const uploadSlip = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file provided" });
    }
    const data = await uploadSalarySlip(
      req.params.id,
      req.file.buffer,
      req.file.mimetype,
    );
    res.json({ message: "Salary slip uploaded", salary: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const slipUrl = async (req, res) => {
  try {
    const url = await getSalarySlipUrl(req.params.id, req.user);
    res.json({ url });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
};
