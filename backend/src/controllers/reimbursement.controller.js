import {
  submitClaim,
  getMyClaims,
  getAllClaims,
  updateClaimStatus,
  getClaimById,
  getPendingTotal,
} from "../services/reimbursement.service.js";

export const submit = async (req, res) => {
  try {
    const { category, amount, description, receipt_url } = req.body;

    if (!receipt_url) {
      return res.status(400).json({
        error: "Receipt image is required",
      });
    }

    const data = await submitClaim(req.user.id, {
      category,
      amount,
      description,
      receipt_url,
    });

    res.status(201).json({ message: "Claim submitted", reimbursement: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
export const myClaims = async (req, res) => {
  try {
    const data = await getMyClaims(req.user.id);
    res.json({ reimbursements: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allClaims = async (req, res) => {
  try {
    const { status } = req.query;
    const data = await getAllClaims(status || null);
    res.json({ reimbursements: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ error: "Status is required" });
    }

    const data = await updateClaimStatus(id, status, req.user.id);
    res.json({ message: `Claim ${status}`, reimbursement: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const getOne = async (req, res) => {
  try {
    const data = await getClaimById(req.params.id);
    res.json({ reimbursement: data });
  } catch (err) {
    res.status(404).json({ error: err.message });
  }
};

export const pendingTotal = async (req, res) => {
  try {
    const data = await getPendingTotal();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
