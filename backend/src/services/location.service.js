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
    .maybeSingle();

  if (error) throw new Error(error.message);
  return data || null;
};

export const getAllLiveLocations = async () => {
  const { data: users, error } = await supabase
    .from("users")
    .select("id, name, designation, location");

  if (error) throw new Error(error.message);

  // Latest location per user. One small query each, so the result does not
  // depend on how many rows the locations table has accumulated.
  const latest = await Promise.all(
    users.map(async (user) => {
      const { data: rows, error: locError } = await supabase
        .from("locations")
        .select("*")
        .eq("user_id", user.id)
        .order("recorded_at", { ascending: false })
        .limit(1);

      if (locError) throw new Error(locError.message);
      return rows.length ? { ...rows[0], users: user } : null;
    }),
  );

  return latest
    .filter(Boolean)
    .sort((a, b) => new Date(b.recorded_at) - new Date(a.recorded_at));
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
