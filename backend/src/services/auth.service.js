import supabase from "../config/supabase.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { isWorkingDate } from "../utils/weeklyOff.js";

export const loginUser = async (email, password) => {
  const { data: user, error } = await supabase
    .from("users")
    .select("*")
    .eq("email", email.toLowerCase().trim())
    .single();

  if (error || !user) {
    throw new Error("Invalid email or password");
  }

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    throw new Error("Invalid email or password");
  }

  const token = jwt.sign(
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      designation: user.designation,
      location: user.location,
      upi_id: user.upi_id,
    },
    process.env.JWT_SECRET,
    { expiresIn: "360d" },
  );

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      designation: user.designation,
      location: user.location,
      upi_id: user.upi_id,
      base_salary: user.base_salary,
      joining_date: user.joining_date,
    },
  };
};

export const getMe = async (userId) => {
  const { data: user, error } = await supabase
    .from("users")
    .select("id, name, email, role, designation, location, upi_id, base_salary, joining_date")
    .eq("id", userId)
    .single();

  if (error || !user) {
    throw new Error("User not found");
  }

  return user;
};

// With `date` ("YYYY-MM-DD"), each employee also gets `is_working_day` for
// that date, so attendance views can tell a weekly off from an absence.
export const getAllUsers = async (date = null) => {
  const { data, error } = await supabase
    .from("users")
    .select("id, name, email, role, designation, location, upi_id, base_salary, joining_date")
    .eq("role", "employee")
    .order("name");

  if (error) throw new Error(error.message);
  if (!date) return data;

  return data.map((user) => ({
    ...user,
    is_working_day: isWorkingDate(user.location, date),
  }));
};

export const updatePassword = async (email, password) => {
  // 1. Find user
  const { data: user, error } = await supabase
    .from("users")
    .select("*")
    .eq("email", email.toLowerCase().trim())
    .single();
  if (error || !user) throw new Error("User not found");

  if (typeof password !== "string" || password.length < 8) {
    throw new Error("Password must be at least 8 characters");
  }

  // 2. Hash password using bcrypt
  const hashedPassword = await bcrypt.hash(password, 10);

  // 3. Update password
  const { error: updateError } = await supabase
    .from("users")
    .update({
      password_hash: hashedPassword,
    })
    .eq("id", user.id);

  if (updateError) throw new Error(updateError.message);

  return { message: "Password updated successfully" };
};
export const createEmployee = async ({
  name,
  email,
  password,
  designation,
  location,
  upi_id,
  base_salary,
  joining_date,
}) => {
  if (!name.trim()) throw new Error("Name is required");

  // 1. Check if email already exists
  const { data: existing } = await supabase
    .from("users")
    .select("id")
    .eq("email", email.toLowerCase().trim())
    .maybeSingle();

  if (existing) throw new Error("Email already registered");

  // 2. Hash password
  const password_hash = await bcrypt.hash(password, 10);

  // 3. Insert new employee
  const { data: user, error } = await supabase
    .from("users")
    .insert({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password_hash,
      role: "employee",
      designation: designation?.trim() || null,
      location: location?.trim() || null,
      upi_id: upi_id?.trim() || null,
      base_salary: base_salary == null || base_salary === "" ? null : Number(base_salary),
      joining_date: joining_date || null,
    })
    .select("id, name, email, role, designation, location, upi_id, base_salary, joining_date")
    .single();

  if (error) throw new Error(error.message);

  return { message: "Employee created successfully", user };
};

export const deleteEmployee = async (userId) => {
  // Prevent deleting admins via this route
  const { data: user, error: fetchError } = await supabase
    .from("users")
    .select("role")
    .eq("id", userId)
    .single();

  if (fetchError || !user) throw new Error("User not found");
  if (user.role !== "employee") {
    throw new Error("Only employee accounts can be deleted here");
  }

  const { error } = await supabase.from("users").delete().eq("id", userId);

  if (error) throw new Error(error.message);
  return { message: "Employee deleted successfully" };
};

export const updateEmployee = async (userId, fields) => {
  const allowed = ["name", "designation", "location", "upi_id", "base_salary", "joining_date"];
  const updates = {};
  for (const key of allowed) {
    if (fields[key] !== undefined) updates[key] = fields[key];
  }
  if (Object.keys(updates).length === 0) throw new Error("No valid fields to update");

  if (updates.name !== undefined) {
    updates.name = String(updates.name ?? "").trim();
    if (!updates.name) throw new Error("Name is required");
  }
  if (updates.base_salary !== undefined && updates.base_salary !== null) {
    const salary = Number(updates.base_salary);
    if (!Number.isFinite(salary) || salary < 0) {
      throw new Error("Salary must be a valid number");
    }
    updates.base_salary = salary;
  }

  // This route manages employees only, never admin or sub-admin accounts
  const { data: target, error: targetError } = await supabase
    .from("users")
    .select("role")
    .eq("id", userId)
    .maybeSingle();
  if (targetError || !target) throw new Error("User not found");
  if (target.role !== "employee") {
    throw new Error("Only employee accounts can be edited here");
  }

  const { data, error } = await supabase
    .from("users")
    .update(updates)
    .eq("id", userId)
    .select("id, name, email, role, designation, location, upi_id, base_salary, joining_date")
    .single();

  if (error) throw new Error(error.message);
  return { message: "Employee updated successfully", user: data };
};
