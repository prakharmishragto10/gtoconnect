import supabase from "../config/supabase.js";

export const submitClaim = async (
  userId,
  { category, amount, description, receipt_url },
) => {
  if (!category || !amount) {
    throw new Error("Category and amount are required");
  }
  if (!receipt_url) {
    throw new Error("Receipt image is required");
  }

  const { data, error } = await supabase
    .from("reimbursements")
    .insert({
      user_id: userId,
      category,
      amount,
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
  const { data, error } = await supabase
    .from("reimbursements")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllClaims = async (status = null) => {
  let query = supabase
    .from("reimbursements")
    .select("*")
    .order("created_at", { ascending: false });

  if (status) query = query.eq("status", status);

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const enriched = await Promise.all(
    data.map(async (claim) => {
      const { data: user } = await supabase
        .from("users")
        .select("id, name, email, designation, location")
        .eq("id", claim.user_id)
        .single();
      return { ...claim, submitter: user };
    }),
  );

  return enriched;
};

export const updateClaimStatus = async (claimId, status, reviewerId) => {
  const allowed = ["approved", "rejected", "paid"];
  if (!allowed.includes(status)) {
    throw new Error("Invalid status");
  }

  const { data, error } = await supabase
    .from("reimbursements")
    .update({
      status,
      reviewed_by: reviewerId,
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", claimId)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getClaimById = async (claimId) => {
  const { data, error } = await supabase
    .from("reimbursements")
    .select("*")
    .eq("id", claimId)
    .single();

  if (error) throw new Error(error.message);

  const { data: user } = await supabase
    .from("users")
    .select("id, name, email, designation, location")
    .eq("id", data.user_id)
    .single();

  return { ...data, submitter: user };
};

export const getPendingTotal = async () => {
  const { data, error } = await supabase
    .from("reimbursements")
    .select("amount")
    .eq("status", "pending");

  if (error) throw new Error(error.message);
  const total = data.reduce((sum, r) => sum + Number(r.amount), 0);
  return { count: data.length, total };
};
