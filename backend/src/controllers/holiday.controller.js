import {
  getHolidays,
  addHoliday,
  deleteHoliday,
} from "../services/holiday.service.js";

export const list = async (req, res) => {
  try {
    const { month, year } = req.query;
    const data = await getHolidays(month, year);
    res.json({ holidays: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const create = async (req, res) => {
  try {
    const { date, name } = req.body || {};
    const data = await addHoliday({ date, name }, req.user.id);
    res.status(201).json({ message: "Holiday added", holiday: data });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

export const remove = async (req, res) => {
  try {
    const data = await deleteHoliday(req.params.id);
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
