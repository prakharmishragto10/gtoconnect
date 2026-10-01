import { createClient } from "@supabase/supabase-js";
import bcrypt from "bcryptjs";
import dotenv from "dotenv";

dotenv.config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function createAdmin() {
  const email = "gracyhr.gto@gmail.com"; // You can change this
  const password = "Gracyhr@globetrekovereas.137"; // You can change this
  const name = "Admin User";

  console.log(`Creating admin with email: ${email}...`);

  // Hash the password
  const password_hash = await bcrypt.hash(password, 10);

  // Try to update existing user first
  let { data, error } = await supabase
    .from("users")
    .update({
      password_hash: password_hash,
      role: "admin",
      name: name,
    })
    .eq("email", email)
    .select();

  if (!data || data.length === 0) {
    // If not found, insert
    console.log("User not found, inserting a new one...");
    const result = await supabase
      .from("users")
      .insert({
        name: name,
        email: email,
        password_hash: password_hash,
        role: "admin",
      })
      .select();
    
    data = result.data;
    error = result.error;
  }

  if (error) {
    console.error("Error creating admin:", error.message);
  } else {
    console.log("Admin created successfully!");
    console.log(data);
  }
}

createAdmin();
