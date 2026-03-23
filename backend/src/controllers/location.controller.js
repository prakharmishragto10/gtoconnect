import {
  updateLocation,
  getMyLastLocation,
  getAllLiveLocations,
  getLocationHistory,
} from "../services/location.service.js";

export const update = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: "latitude and longitude required" });
    }

    const data = await updateLocation(req.user.id, latitude, longitude);
    res.json({ message: "Location updated", location: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const myLocation = async (req, res) => {
  try {
    const data = await getMyLastLocation(req.user.id);
    res.json({ location: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allLive = async (req, res) => {
  try {
    const data = await getAllLiveLocations();
    res.json({ locations: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const history = async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit } = req.query;
    const data = await getLocationHistory(userId, limit || 50);
    res.json({ locations: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
