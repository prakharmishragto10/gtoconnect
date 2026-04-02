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

export const updatePassword = async (userId, newPassword) => {
  const hashed = await bcrypt.hash(newPassword, 10);

  const { error } = await supabase
    .from("users")
    .update({ password_hash: hashed })
    .eq("id", userId);

  if (error) throw new Error(error.message);

  return { message: "Password updated successfully" };
};
