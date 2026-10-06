import supabase from "../config/supabase.js";
import { fetchAll } from "../utils/db.js";

const SUBMITTER_FIELDS = "id, name, email, designation, location";

// Receipts must be files uploaded through /api/upload, not arbitrary links
const receiptUrlPrefix = () =>
  `${(process.env.SUPABASE_URL || "").replace(/\/+$/, "")}/storage/v1/object/public/receipts/`;

// Allowed status moves. "paid" and "rejected" are final.
const TRANSITIONS = {
  pending: ["approved", "rejected"],
  approved: ["paid", "rejected"],
  paid: [],
  rejected: [],
};

// Attach the submitting user to each row with one query instead of one per row
export const attachSubmitters = async (rows) => {
  const ids = [...new Set(rows.map((r) => r.user_id).filter(Boolean))];
  if (ids.length === 0) return rows.map((r) => ({ ...r, submitter: null }));

  const { data: users, error } = await supabase
    .from("users")
    .select(SUBMITTER_FIELDS)
    .in("id", ids);
  if (error) throw new Error(error.message);

  const byId = new Map(users.map((u) => [u.id, u]));
  return rows.map((r) => ({ ...r, submitter: byId.get(r.user_id) || null }));
};

export const submitClaim = async (
  userId,
  { category, amount, description, receipt_url },
) => {
  const numericAmount = Number(amount);
  if (!category || amount == null || amount === "") {
    throw new Error("Category and amount are required");
  }
  if (!Number.isFinite(numericAmount) || numericAmount <= 0) {
    throw new Error("Amount must be a positive number");
  }
  if (!receipt_url) {
    throw new Error("Receipt image is required");
  }
  if (typeof receipt_url !== "string" || !receipt_url.startsWith(receiptUrlPrefix())) {
    throw new Error("Invalid receipt. Please upload the receipt again");
  }

  const { data, error } = await supabase
    .from("reimbursements")
    .insert({
      user_id: userId,
      category,
      amount: numericAmount,
      description,
      receipt_url,
      status: "pending",
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getMyClaims = async (userId) => {
  return fetchAll(() =>
    supabase
      .from("reimbursements")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .order("id"),
  );
};

export const getAllClaims = async (status = null) => {
  const data = await fetchAll(() => {
    let query = supabase.from("reimbursements").select("*");
    if (status) query = query.eq("status", status);
    return query.order("created_at", { ascending: false }).order("id");
  });

  return attachSubmitters(data);
};

export const updateClaimStatus = async (claimId, status, reviewerId) => {
  const allowed = ["approved", "rejected", "paid"];
  if (!allowed.includes(status)) {
    throw new Error("Invalid status");
  }

  // Fetch current claim to enforce status progression
  const { data: currentClaim, error: fetchError } = await supabase
    .from("reimbursements")
    .select("status")
    .eq("id", claimId)
    .maybeSingle();

  if (fetchError || !currentClaim) throw new Error("Claim not found");

  if (status === "paid" && currentClaim.status !== "approved") {
    throw new Error("Claim must be approved before it can be marked as paid");
  }
  if (!(TRANSITIONS[currentClaim.status] || []).includes(status)) {
    throw new Error(`A ${currentClaim.status} claim cannot be changed to ${status}`);
  }

  const { data, error } = await supabase
    .from("reimbursements")
    .update({
      status,
      reviewed_by: reviewerId,
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", claimId)
    // Guards against two reviewers acting on the same claim at once
    .eq("status", currentClaim.status)
    .select()
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) throw new Error("Claim was already updated. Please refresh");
  return data;
};

export const getClaimById = async (claimId) => {
  const { data, error } = await supabase
    .from("reimbursements")
    .select("*")
    .eq("id", claimId)
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) throw new Error("Claim not found");

  const [claim] = await attachSubmitters([data]);
  return claim;
};

export const getPendingTotal = async () => {
  const data = await fetchAll(() =>
    supabase
      .from("reimbursements")
      .select("id, amount")
      .eq("status", "pending")
      .order("id"),
  );

  const total = data.reduce((sum, r) => sum + Number(r.amount), 0);
  return { count: data.length, total };
};
