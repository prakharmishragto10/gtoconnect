import supabase from "../config/supabase.js";
import { fetchAll } from "../utils/db.js";
import { attachSubmitters } from "./reimbursement.service.js";

export const submitTravel = async (userId, data) => {
  const { place, start_date, end_date, work, reason } = data;

  if (!place || !start_date || !end_date || !work || !reason) {
    throw new Error("All fields are required");
  }
  if (String(end_date) < String(start_date)) {
    throw new Error("End date cannot be before start date");
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
  const data = await fetchAll(() => {
    let query = supabase.from("travel_requests").select("*");
    if (status) query = query.eq("status", status);
    return query.order("created_at", { ascending: false }).order("id");
  });

  const enriched = await attachSubmitters(data);
  return enriched.map((req) => ({ ...req, users: req.submitter }));
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
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) throw new Error("Travel request not found");
  return data;
};
