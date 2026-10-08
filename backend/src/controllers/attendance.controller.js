import {
  checkIn,
  checkOut,
  getTodayStatus,
  getMyAttendance,
  getAllTodayAttendance,
  getMonthlyReport,
  getAllAttendance,
  getMonthCalendar,
  markPresent,
} from "../services/attendance.service.js";

export const checkin = async (req, res) => {
  try {
    // Check-in must carry the device's position. App versions from before
    // location became mandatory send none, so they are told to update.
    const body = req.body || {};
    const latitude = Number(body.latitude);
    const longitude = Number(body.longitude);
    const hasLocation =
      body.latitude != null &&
      body.longitude != null &&
      body.latitude !== "" &&
      body.longitude !== "" &&
      Number.isFinite(latitude) &&
      Number.isFinite(longitude) &&
      Math.abs(latitude) <= 90 &&
      Math.abs(longitude) <= 180;
    if (!hasLocation) {
      return res.status(400).json({
        error:
          "Location is required to check in. Please update GTO Connect to the latest version and allow location access.",
      });
    }

    const data = await checkIn(req.user.id, { latitude, longitude });
    res.json({ message: "Checked in successfully", attendance: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const checkout = async (req, res) => {
  try {
    const data = await checkOut(req.user.id);
    res.json({ message: "Checked out successfully", attendance: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const today = async (req, res) => {
  try {
    const data = await getTodayStatus(req.user.id);
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const myHistory = async (req, res) => {
  try {
    const { date, month, year } = req.query;
    const data = await getMyAttendance(req.user.id, { date, month, year });
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allToday = async (req, res) => {
  try {
    const { date, month, year } = req.query;
    const data = await getAllTodayAttendance({ date, month, year });
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const monthlyReport = async (req, res) => {
  try {
    const { month, year } = req.query;
    if (!month || !year) {
      return res.status(400).json({ error: "month and year required" });
    }
    const data = await getMonthlyReport(month, year);
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const allHistory = async (req, res) => {
  try {
    const data = await getAllAttendance();
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const employeeHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    const { date, month, year } = req.query;
    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }
    const data = await getMyAttendance(userId, { date, month, year });
    res.json({ attendance: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const myCalendar = async (req, res) => {
  try {
    const { month, year } = req.query;
    const data = await getMonthCalendar(req.user.id, month, year);
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const employeeCalendar = async (req, res) => {
  try {
    const { month, year } = req.query;
    const data = await getMonthCalendar(req.params.userId, month, year);
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const markEmployeePresent = async (req, res) => {
  try {
    const { userId, date } = req.body || {};
    if (!userId || !date) {
      return res.status(400).json({ error: "userId and date are required" });
    }
    const data = await markPresent(userId, date);
    res.json({ message: "Marked present", attendance: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
