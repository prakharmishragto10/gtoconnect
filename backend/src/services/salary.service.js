import supabase from "../config/supabase.js";

export const calculateSalary = (baseSalary, reimbursements = 0) => {
  const net = baseSalary + reimbursements;
  return { net };
};

export const generateMonthlySalary = async (month, year) => {
  const { data: employees, error: empError } = await supabase
    .from("users")
    .select("id, name, base_salary")
    .eq("role", "employee");

  if (empError) throw new Error(empError.message);

  const results = [];

  for (const emp of employees) {
    const from = `${year}-${String(month).padStart(2, "0")}-01`;
    const to = `${year}-${String(month).padStart(2, "0")}-31`;

    const { data: claims } = await supabase
      .from("reimbursements")
      .select("amount")
      .eq("user_id", emp.id)
      .eq("status", "approved")
      .gte("created_at", from)
      .lte("created_at", to);

    const reimbursements = (claims || []).reduce(
      (sum, c) => sum + Number(c.amount),
      0,
    );

    const base = Number(emp.base_salary) || 15000;
    const { net } = calculateSalary(base, reimbursements);

    const { data, error } = await supabase
      .from("salary_records")
      .upsert(
        {
          user_id: emp.id,
          month,
          year,
          base_salary: base,
          reimbursements,
          net_salary: net,
          status: "pending",
        },
        { onConflict: "user_id,month,year" },
      )
      .select()
      .single();

    if (error) throw new Error(error.message);
    results.push({ ...data, name: emp.name });
  }

  return results;
};

export const getMySalary = async (userId, month, year) => {
  const { data, error } = await supabase
    .from("salary_records")
    .select("*")
    .eq("user_id", userId)
    .eq("month", month)
    .eq("year", year)
    .single();

  if (error && error.code !== "PGRST116") throw new Error(error.message);
  return data || null;
};

export const getMySalaryHistory = async (userId) => {
  const { data, error } = await supabase
    .from("salary_records")
    .select("*")
    .eq("user_id", userId)
    .order("year", { ascending: false })
    .order("month", { ascending: false });

  if (error) throw new Error(error.message);
  return data;
};

export const getAllSalaries = async (month, year) => {
  const { data, error } = await supabase
    .from("salary_records")
    .select(`*, users (id, name, email, designation, upi_id)`)
    .eq("month", month)
    .eq("year", year)
    .order("created_at", { ascending: true });

  if (error) throw new Error(error.message);
  return data;
};

export const markSalaryPaid = async (salaryId) => {
  const { data, error } = await supabase
    .from("salary_records")
    .update({
      status: "paid",
      paid_at: new Date().toISOString(),
    })
    .eq("id", salaryId)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
};

export const getPayrollSummary = async (month, year) => {
  const { data, error } = await supabase
    .from("salary_records")
    .select("base_salary, reimbursements, net_salary, status")
    .eq("month", month)
    .eq("year", year);

  if (error) throw new Error(error.message);

  const summary = data.reduce(
    (acc, s) => ({
      gross: acc.gross + Number(s.base_salary),
      reimbursements: acc.reimbursements + Number(s.reimbursements),
      net: acc.net + Number(s.net_salary),
      paid: acc.paid + (s.status === "paid" ? 1 : 0),
      pending: acc.pending + (s.status === "pending" ? 1 : 0),
    }),
    { gross: 0, reimbursements: 0, net: 0, paid: 0, pending: 0 },
  );

  return summary;
};
