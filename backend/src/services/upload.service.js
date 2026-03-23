import supabase from "../config/supabase.js";

export const uploadReceipt = async (fileBuffer, fileName, mimeType) => {
  const filePath = `receipts/${Date.now()}_${fileName}`;

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
