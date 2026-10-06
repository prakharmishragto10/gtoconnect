import supabase from "../config/supabase.js";
import { updateLocation } from "./location.service.js";

const getTodayDate = () => {
  try {
    return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kolkata" }).format(new Date());
  } catch (_) {
    return new Date().toISOString().split("T")[0];
  }
};

export const checkIn = async (userId, locationData = null) => {
  const today = getTodayDate();

  const { data: existing } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .single();

  if (existing) {
    throw new Error("Already checked in today");
  }

  const checkinTime = new Date();
  
  // Calculate hour and minute in Asia/Kolkata (IST) timezone
  let hour = checkinTime.getHours();
  let minute = checkinTime.getMinutes();
  try {
    const istFormatter = new Intl.DateTimeFormat("en-IN", {
      timeZone: "Asia/Kolkata",
      hour: "numeric",
      minute: "numeric",
      hourCycle: "h23",
    });
    const parts = istFormatter.formatToParts(checkinTime);
    const h = parts.find((p) => p.type === "hour")?.value;
    const m = parts.find((p) => p.type === "minute")?.value;
    if (h != null) hour = parseInt(h, 10);
    if (m != null) minute = parseInt(m, 10);
  } catch (_) {}

  // After 10:45 AM is marked as "late"
  const isLate = hour > 10 || (hour === 10 && minute > 45);
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
  const today = getTodayDate();

  const { data: existing } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .single();

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
  const today = getTodayDate();

  const { data, error } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .single();

  if (error && error.code !== "PGRST116") throw new Error(error.message);
  return data || null;
};

export const getMyAttendance = async (userId, filters = {}) => {
  let query = supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId);

  if (filters.date) {
    query = query.eq("date", filters.date);
  } else if (filters.month && filters.year) {
    const m = String(filters.month).padStart(2, "0");
    const y = String(filters.year);
    const lastDay = new Date(Number(filters.year), Number(filters.month), 0).getDate();
    const from = `${y}-${m}-01`;
    const to = `${y}-${m}-${String(lastDay).padStart(2, "0")}`;
    query = query.gte("date", from).lte("date", to);
  } else if (filters.year) {
    const from = `${filters.year}-01-01`;
    const to = `${filters.year}-12-31`;
    query = query.gte("date", from).lte("date", to);
  }

  const { data, error } = await query.order("date", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllTodayAttendance = async (filters = {}) => {
  let query = supabase
    .from("attendance")
    .select(`*, users (id, name, email, designation, location)`);

  if (filters.date) {
    query = query.eq("date", filters.date);
  } else if (filters.month && filters.year) {
    const m = String(filters.month).padStart(2, "0");
    const y = String(filters.year);
    const lastDay = new Date(Number(filters.year), Number(filters.month), 0).getDate();
    const from = `${y}-${m}-01`;
    const to = `${y}-${m}-${String(lastDay).padStart(2, "0")}`;
    query = query.gte("date", from).lte("date", to);
  } else if (filters.year) {
    const from = `${filters.year}-01-01`;
    const to = `${filters.year}-12-31`;
    query = query.gte("date", from).lte("date", to);
  } else {
    const today = getTodayDate();
    query = query.eq("date", today);
  }

  const { data, error } = await query.order("checked_in_at", { ascending: true });

  if (error) throw new Error(error.message);
  return data;
};

export const getMonthlyReport = async (month, year) => {
  const m = String(month).padStart(2, "0");
  const y = String(year);
  const lastDay = new Date(Number(year), Number(month), 0).getDate();
  const from = `${y}-${m}-01`;
  const to = `${y}-${m}-${String(lastDay).padStart(2, "0")}`;

  const { data, error } = await supabase
    .from("attendance")
    .select(`*, users (id, name, email, designation)`)
    .gte("date", from)
    .lte("date", to)
    .order("date", { ascending: false });

  if (error) throw new Error(error.message);

  return data;
};

export const getAllAttendance = async () => {
  const { data, error } = await supabase
    .from("attendance")
    .select(`*, users (id, name, email, designation, location)`)
    .order("date", { ascending: false })
    .order("checked_in_at", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};
