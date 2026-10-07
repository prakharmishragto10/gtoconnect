import supabase from "../config/supabase.js";

// Company holidays marked by the admin. A holiday that falls on someone's
// working day is a paid day off: no check-in needed, never an absence.

const pad = (n) => String(n).padStart(2, "0");

const parsePeriod = (month, year) => {
  const m = parseInt(month, 10);
  const y = parseInt(year, 10);
  if (!(m >= 1 && m <= 12) || !(y >= 2000 && y <= 2100)) {
    throw new Error("Valid month and year required");
  }
  return { m, y };
};

const monthBounds = (m, y) => ({
  from: `${y}-${pad(m)}-01`,
  to: `${y}-${pad(m)}-${pad(new Date(y, m, 0).getDate())}`,
});

// The holidays table is added by migrations/002_holidays.sql. Until that has
// been run, behave as if there are no holidays instead of breaking payroll.
const tableMissing = (error) =>
  error?.code === "42P01" ||
  error?.code === "PGRST205" ||
  /holidays.*(does not exist|schema cache)/i.test(error?.message || "");

export const getHolidays = async (month, year) => {
  const { m, y } = parsePeriod(month, year);
  const { from, to } = monthBounds(m, y);

  const { data, error } = await supabase
    .from("holidays")
    .select("id, date, name")
    .gte("date", from)
    .lte("date", to)
    .order("date");

  if (error) {
    if (tableMissing(error)) return [];
    throw new Error(error.message);
  }
  return data.map((h) => ({ ...h, date: String(h.date).slice(0, 10) }));
};

// Set of "YYYY-MM-DD" holiday dates in a month, for salary and attendance
export const getHolidayDates = async (month, year) => {
  const holidays = await getHolidays(month, year);
  return new Set(holidays.map((h) => h.date));
};

export const isHoliday = async (date) => {
  const match = /^(\d{4})-(\d{2})-\d{2}$/.exec(String(date || ""));
  if (!match) return false;
  const dates = await getHolidayDates(match[2], match[1]);
  return dates.has(date);
};

export const addHoliday = async ({ date, name }, userId) => {
  const cleanDate = String(date || "").trim();
  const cleanName = String(name || "").trim();

  const parsed = /^(\d{4})-(\d{2})-(\d{2})$/.exec(cleanDate);
  const valid =
    parsed && new Date(`${cleanDate}T00:00:00Z`).toISOString().slice(0, 10) === cleanDate;
  if (!valid) throw new Error("A valid date is required");
  if (!cleanName) throw new Error("Holiday name is required");
  if (cleanName.length > 80) throw new Error("Holiday name is too long");

  const { data, error } = await supabase
    .from("holidays")
    .insert({ date: cleanDate, name: cleanName, created_by: userId })
    .select("id, date, name")
    .single();

  if (error) {
    if (error.code === "23505") {
      throw new Error("That date is already marked as a holiday");
    }
    if (tableMissing(error)) {
      throw new Error("Holidays are not set up yet. Run migrations/002_holidays.sql in Supabase");
    }
    throw new Error(error.message);
  }
  return data;
};

export const deleteHoliday = async (id) => {
  const { data, error } = await supabase
    .from("holidays")
    .delete()
    .eq("id", id)
    .select("id")
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) throw new Error("Holiday not found");
  return { message: "Holiday removed" };
};
