import {
  submitTravel,
  getMyTravelRequests,
  getAllTravelRequests,
  updateTravelStatus,
} from "../services/travel.service.js";

export const submit = async (req, res) => {
  try {
    const { place, start_date, end_date, work, reason } = req.body;
    const data = await submitTravel(req.user.id, {
      place,
      start_date,
      end_date,
      work,
      reason,
    });
    res.status(201).json({ message: "Travel request submitted", travel: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const myRequests = async (req, res) => {
  try {
    const data = await getMyTravelRequests(req.user.id);
    res.json({ travels: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allRequests = async (req, res) => {
  try {
    const { status } = req.query;
    const data = await getAllTravelRequests(status || null);
    res.json({ travels: data });
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

    const data = await updateTravelStatus(id, status, req.user.id);
    res.json({ message: `Travel request ${status}`, travel: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
