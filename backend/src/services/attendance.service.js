import supabase from "../config/supabase.js";

export const checkIn = async (userId) => {
  const today = new Date().toISOString().split("T")[0];

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
  const hour = checkinTime.getHours();
  const status = hour >= 10 ? "late" : "present";

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
  return data;
};

export const checkOut = async (userId) => {
  const today = new Date().toISOString().split("T")[0];

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
  const today = new Date().toISOString().split("T")[0];

  const { data, error } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .eq("date", today)
    .single();

  if (error && error.code !== "PGRST116") throw new Error(error.message);
  return data || null;
};

export const getMyAttendance = async (userId) => {
  const { data, error } = await supabase
    .from("attendance")
    .select("*")
    .eq("user_id", userId)
    .order("date", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllTodayAttendance = async () => {
  const today = new Date().toISOString().split("T")[0];

  const { data, error } = await supabase
    .from("attendance")
    .select(`*, users (id, name, email, designation, location)`)
    .eq("date", today)
    .order("checked_in_at", { ascending: true });

  if (error) throw new Error(error.message);
  return data;
};

export const getMonthlyReport = async (month, year) => {
  const from = `${year}-${String(month).padStart(2, "0")}-01`;
  const to = `${year}-${String(month).padStart(2, "0")}-31`;

  const { data, error } = await supabase
    .from("attendance")
    .select(`*, users (id, name, email, designation)`)
    .gte("date", from)
    .lte("date", to)
    .order("date", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};
