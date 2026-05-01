import supabase from "../config/supabase.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

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
    { expiresIn: "7d" },
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
    },
  };
};

export const getMe = async (userId) => {
  const { data: user, error } = await supabase
    .from("users")
    .select("id, name, email, role, designation, location, upi_id, base_salary")
    .eq("id", userId)
    .single();

  if (error || !user) {
    throw new Error("User not found");
  }

  return user;
};

export const getAllUsers = async () => {
  const { data, error } = await supabase
    .from("users")
    .select("id, name, email, role, designation, location, upi_id, base_salary")
    .eq("role", "employee")
    .order("name");

  if (error) throw new Error(error.message);
  return data;
};

export const updatePassword = async (email, password) => {
  // 1. Find user
  const { data: user, error } = await supabase
    .from("users")
    .select("*")
    .eq("email", email.toLowerCase().trim())
    .single();
  // ADD THIS 👇
  console.log("Looking for email:", email.toLowerCase().trim());
  console.log("Supabase result - user:", user);
  console.log("Supabase result - error:", JSON.stringify(error));

  if (error || !user) throw new Error("User not found");

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
}) => {
  // 1. Check if email already exists
  const { data: existing } = await supabase
    .from("users")
    .select("id")
    .eq("email", email.toLowerCase().trim())
    .single();

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
      base_salary: base_salary || null,
    })
    .select("id, name, email, role, designation, location, upi_id, base_salary")
    .single();

  if (error) throw new Error(error.message);

  return { message: "Employee created successfully", user };
};
