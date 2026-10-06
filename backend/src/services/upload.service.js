import supabase from "../config/supabase.js";

export const uploadReceipt = async (fileBuffer, fileName, mimeType) => {
  // Storage keys reject non-ASCII and several special characters
  const safeName =
    String(fileName || "receipt")
      .replace(/[^A-Za-z0-9._-]/g, "_")
      .slice(-80) || "receipt";
  const filePath = `receipts/${Date.now()}_${safeName}`;

  const { data, error } = await supabase.storage
    .from("receipts")
    .upload(filePath, fileBuffer, {
      contentType: mimeType,
      upsert: false,
    });

  if (error) throw new Error(error.message);

  const { data: urlData } = supabase.storage
    .from("receipts")
    .getPublicUrl(filePath);

  return urlData.publicUrl;
};
