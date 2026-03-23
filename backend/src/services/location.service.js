import supabase from "../config/supabase.js";

export const updateLocation = async (userId, latitude, longitude) => {
  const { data, error } = await supabase
    .from("locations")
    .insert({
      user_id: userId,
      latitude,
      longitude,
      recorded_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getMyLastLocation = async (userId) => {
  const { data, error } = await supabase
    .from("locations")
    .select("*")
    .eq("user_id", userId)
    .order("recorded_at", { ascending: false })
    .limit(1)
    .single();

  if (error && error.code !== "PGRST116") throw new Error(error.message);
  return data || null;
};

export const getAllLiveLocations = async () => {
  const { data, error } = await supabase
    .from("locations")
    .select(
      `
      *,
      users (id, name, designation, location)
    `,
    )
    .order("recorded_at", { ascending: false });

  if (error) throw new Error(error.message);

  // Return only latest location per user
  const seen = new Set();
  const latest = data.filter((row) => {
    if (seen.has(row.user_id)) return false;
    seen.add(row.user_id);
    return true;
  });

  return latest;
};

export const getLocationHistory = async (userId, limit = 50) => {
  const { data, error } = await supabase
    .from("locations")
    .select("*")
    .eq("user_id", userId)
    .order("recorded_at", { ascending: false })
    .limit(limit);

  if (error) throw new Error(error.message);
  return data;
};
