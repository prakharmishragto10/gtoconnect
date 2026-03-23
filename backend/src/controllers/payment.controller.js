import {
  recordPayment,
  getPaymentHistory,
  getAllPayments,
} from "../services/payment.service.js";

export const record = async (req, res) => {
  try {
    const { userId, amount, upiId, type, referenceId } = req.body;
    if (!userId || !amount || !upiId || !type) {
      return res
        .status(400)
        .json({ error: "userId, amount, upiId, type required" });
    }
    const data = await recordPayment({
      userId,
      amount,
      upiId,
      type,
      referenceId,
    });
    res.status(201).json({ message: "Payment recorded", payment: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const myHistory = async (req, res) => {
  try {
    const data = await getPaymentHistory(req.user.id);
    res.json({ payments: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allPayments = async (req, res) => {
  try {
    const data = await getAllPayments();
    res.json({ payments: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
