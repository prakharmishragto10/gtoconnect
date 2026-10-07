import supabase from "../config/supabase.js";
import { fetchAll } from "../utils/db.js";
import { updateLocation } from "./location.service.js";
import { weeklyOffRule, isWorkingDay } from "../utils/weeklyOff.js";
import { getHolidays } from "./holiday.service.js";

const IST_OFFSET = "+05:30";
// After 10:45 AM IST a check-in is marked "late"
const LATE_AFTER = { hour: 10, minute: 45 };
// Anyone still on duty at 6:30 PM IST is checked out automatically
const AUTO_CHECKOUT_TIME = "18:30:00";

const getTodayDate = () => {
  try {
    return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kolkata" }).format(new Date());
  } catch (_) {
    return new Date(Date.now() + 5.5 * 60 * 60 * 1000).toISOString().split("T")[0];
  }
};

// When an open attendance row should be closed, or null if it is not due yet.
const autoCheckoutAt = (row, now) => {
  const cutoff = new Date(`${row.date}T${AUTO_CHECKOUT_TIME}${IST_OFFSET}`);
  if (new Date(row.checked_in_at) < cutoff) {
    return now >= cutoff ? cutoff : null;
  }
  // Checked in after the cutoff: close the record at the end of that day
  const endOfDay = new Date(`${row.date}T23:59:59${IST_OFFSET}`);
  return now > endOfDay ? endOfDay : null;
};

// Closes every open record that is past the 6:30 PM cutoff. There is no
// scheduler, so this runs before each attendance read/write instead.
export const autoCheckoutDue = async (userId = null) => {
  try {
    let query = supabase
      .from("attendance")
      .select("id, date, checked_in_at")
      .is("checked_out_at", null)
      .lte("date", getTodayDate());
    if (userId) query = query.eq("user_id", userId);

    const { data: open, error } = await query;
    if (error || !open?.length) return;

    const now = new Date();
    await Promise.all(
      open.map((row) => {
        const at = autoCheckoutAt(row, now);
        if (!at) return null;
        return supabase
          .from("attendance")
          .update({ checked_out_at: at.toISOString() })
          .eq("id", row.id)
          .is("checked_out_at", null);
      }),
    );
  } catch (err) {
    console.error("Auto checkout failed:", err.message);
  }
};

const applyDateFilters = (query, filters) => {
  const month = parseInt(filters.month, 10);
  const year = parseInt(filters.year, 10);

  if (filters.date) {
    return query.eq("date", filters.date);
  }
  if (month >= 1 && month <= 12 && year) {
    const m = String(month).padStart(2, "0");
    const lastDay = new Date(year, month, 0).getDate();
    return query
      .gte("date", `${year}-${m}-01`)
      .lte("date", `${year}-${m}-${String(lastDay).padStart(2, "0")}`);
  }
  if (year) {
    return query.gte("date", `${year}-01-01`).lte("date", `${year}-12-31`);
  }
  return null;
};

export const checkIn = async (userId, locationData = null) => {
  await autoCheckoutDue(userId);
  const today = getTodayDate();

  const { data: existing, error: existingError } = await supabase
    .from("attendance")
    .select("id")
    .eq("user_id", userId)
    .eq("date", today)
    .limit(1);

  if (existingError) throw new Error(existingError.message);
  if (existing.length > 0) {
    throw new Error("Already checked in today");
  }

  const checkinTime = new Date();

  // Calculate hour and minute in Asia/Kolkata (IST) timezone
  const ist = new Date(checkinTime.getTime() + 5.5 * 60 * 60 * 1000);
  const hour = ist.getUTCHours();
  const minute = ist.getUTCMinutes();

  const isLate =
    hour > LATE_AFTER.hour || (hour === LATE_AFTER.hour && minute > LATE_AFTER.minute);
  const status = isLate ? "late" : "present";

  const { data, error } = await supabase
    .from("attendance")
    .insert({
      user_id: userId,
      date: today,
      checked_in_at: checkinTime.toISOString(),
      status,
    })
    .select()
    .single();

  if (error) throw new Error(error.message);

  if (locationData && locationData.latitude != null && locationData.longitude != null) {
    try {
      await updateLocation(userId, locationData.latitude, locationData.longitude);
    } catch (_) {}
  }

  return data;
};

export const checkOut = async (userId) => {
  await autoCheckoutDue(userId);
  const today = getTodayDate();

  const { data: existing } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .maybeSingle();

  if (!existing) throw new Error("Not checked in yet");
  if (existing.checked_out_at) throw new Error("Already checked out today");

  const { data, error } = await supabase
    .from("attendance")
    .update({ checked_out_at: new Date().toISOString() })
    .eq("id", existing.id)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getTodayStatus = async (userId) => {
  await autoCheckoutDue(userId);
  const today = getTodayDate();

  const { data, error } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .maybeSingle();

  if (error) throw new Error(error.message);
  return data || null;
};

export const getMyAttendance = async (userId, filters = {}) => {
  await autoCheckoutDue(userId);

  return fetchAll(() => {
    const base = supabase.from("attendance").select("*").eq("user_id", userId);
    const query = applyDateFilters(base, filters) || base;
    return query.order("date", { ascending: false }).order("id");
  });
};

export const getAllTodayAttendance = async (filters = {}) => {
  await autoCheckoutDue();

  return fetchAll(() => {
    const base = supabase
      .from("attendance")
      .select(`*, users (id, name, email, designation, location)`);
    const query = applyDateFilters(base, filters) || base.eq("date", getTodayDate());
    return query.order("checked_in_at", { ascending: true }).order("id");
  });
};

export const getMonthlyReport = async (month, year) => {
  await autoCheckoutDue();

  return fetchAll(() => {
    const base = supabase
      .from("attendance")
      .select(`*, users (id, name, email, designation)`);
    const query = applyDateFilters(base, { month, year });
    if (!query) throw new Error("Valid month and year required");
    return query.order("date", { ascending: false }).order("id");
  });
};

export const getAllAttendance = async () => {
  await autoCheckoutDue();

  return fetchAll(() =>
    supabase
      .from("attendance")
      .select(`*, users (id, name, email, designation, location)`)
      .order("date", { ascending: false })
      .order("checked_in_at", { ascending: false })
      .order("id"),
  );
};

// Day-by-day view of one month for one employee, including the days with no
// check-in: "absent" on a working day, "off" on a weekly off, "holiday" on a
// company holiday. Uses the same rules as salary calculation. Days before the
// joining date, and today or later with no check-in yet, are left out
// (holidays are listed even when they are still to come).
export const getMonthCalendar = async (userId, month, year) => {
  const m = parseInt(month, 10);
  const y = parseInt(year, 10);
  if (!(m >= 1 && m <= 12) || !(y >= 2000 && y <= 2100)) {
    throw new Error("Valid month and year required");
  }

  await autoCheckoutDue(userId);

  const { data: user, error: userError } = await supabase
    .from("users")
    .select("id, location, joining_date")
    .eq("id", userId)
    .maybeSingle();
  if (userError) throw new Error(userError.message);
  if (!user) throw new Error("Employee not found");

  const pad = (n) => String(n).padStart(2, "0");
  const lastDay = new Date(y, m, 0).getDate();
  const records = await fetchAll(() =>
    supabase
      .from("attendance")
      .select("*")
      .eq("user_id", userId)
      .gte("date", `${y}-${pad(m)}-01`)
      .lte("date", `${y}-${pad(m)}-${pad(lastDay)}`)
      .order("id"),
  );
  const byDate = new Map(records.map((r) => [String(r.date).slice(0, 10), r]));

  const today = getTodayDate();
  const joined = user.joining_date ? String(user.joining_date).slice(0, 10) : null;
  const rule = weeklyOffRule(user.location);
  const holidayNames = new Map(
    (await getHolidays(m, y)).map((h) => [h.date, h.name]),
  );

  const days = [];
  const summary = {
    present: 0,
    late: 0,
    absent: 0,
    off: 0,
    holiday: 0,
    working_days: 0,
  };

  for (let day = 1; day <= lastDay; day++) {
    const date = `${y}-${pad(m)}-${pad(day)}`;
    const working = isWorkingDay(rule, y, m, day);
    if (working) summary.working_days++;

    const record = byDate.get(date);
    if (record) {
      const status = record.status === "late" ? "late" : "present";
      summary[status]++;
      days.push({ ...record, date, status });
      continue;
    }

    if (joined && date < joined) continue;

    const holidayName = working ? holidayNames.get(date) : undefined;
    if (!holidayName && date >= today) continue;

    const status = holidayName ? "holiday" : working ? "absent" : "off";
    summary[status]++;
    days.push({
      date,
      status,
      holiday_name: holidayName || null,
      user_id: userId,
      checked_in_at: null,
      checked_out_at: null,
    });
  }

  days.reverse(); // newest first, like the other history lists
  return { days, summary, joining_date: joined };
};
