import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import supabase from "../config/supabase.js";

dotenv.config();

const auth = async (req, res, next) => {
  const header = req.headers.authorization;

  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No token provided" });
  }

  const token = header.split(" ")[1];

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }

  // Re-check the account on every request so deleted users lose access
  // immediately and role changes take effect without waiting for token expiry.
  let user;
  try {
    const result = await supabase
      .from("users")
      .select("id, role")
      .eq("id", decoded.id)
      .maybeSingle();
    if (result.error) throw new Error(result.error.message);
    user = result.data;
  } catch (err) {
    // Express 4 does not catch rejections from async middleware
    return res.status(500).json({ error: "Could not verify account" });
  }
  if (!user) {
    return res.status(401).json({ error: "Account no longer exists" });
  }

  req.user = { ...decoded, role: user.role };
  next();
};

// Full admin only: team management, passwords, location, travel, payments
export const adminOnly = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({ error: "Admin access only" });
  }
  next();
};

// Admin or sub-admin: claims, salary and attendance review
export const staffOnly = (req, res, next) => {
  if (req.user.role !== "admin" && req.user.role !== "subadmin") {
    return res.status(403).json({ error: "Admin access only" });
  }
  next();
};

export default auth;
