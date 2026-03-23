import supabase from "../config/supabase.js";

export const recordPayment = async ({
  userId,
  amount,
  upiId,
  type,
  referenceId,
}) => {
  const { data, error } = await supabase
    .from("payments")
    .insert({
      user_id: userId,
      amount,
      upi_id: upiId,
      type,
      reference_id: referenceId || null,
      status: "success",
      paid_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getPaymentHistory = async (userId) => {
  const { data, error } = await supabase
    .from("payments")
    .select("*")
    .eq("user_id", userId)
    .order("paid_at", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllPayments = async () => {
  const { data, error } = await supabase
    .from("payments")
    .select(`*, users (id, name, email, upi_id)`)
    .order("paid_at", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};
