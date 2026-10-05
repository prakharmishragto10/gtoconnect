import supabase from "../config/supabase.js";

export const submitTravel = async (userId, data) => {
  const { place, start_date, end_date, work, reason } = data;

  if (!place || !start_date || !end_date || !work || !reason) {
    throw new Error("All fields are required");
  }

  const { data: record, error } = await supabase
    .from("travel_requests")
    .insert([
      {
        user_id: userId,
        place,
        start_date,
        end_date,
        work,
        reason,
        status: "pending",
      },
    ])
    .select()
    .single();

  if (error) throw new Error(error.message);
  return record;
};

export const getMyTravelRequests = async (userId) => {
  const { data, error } = await supabase
    .from("travel_requests")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllTravelRequests = async (status = null) => {
  let query = supabase
    .from("travel_requests")
    .select("*, users(id, name, email)")
    .order("created_at", { ascending: false });

  if (status) {
    query = query.eq("status", status);
  }

  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return data;
};

export const updateTravelStatus = async (id, status, adminId) => {
  const validStatuses = ["approved", "rejected"];
  if (!validStatuses.includes(status)) {
    throw new Error("Invalid status. Must be 'approved' or 'rejected'.");
  }

  const { data, error } = await supabase
    .from("travel_requests")
    .update({ status, reviewed_by: adminId, reviewed_at: new Date().toISOString() })
    .eq("id", id)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};
