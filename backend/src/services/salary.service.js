import supabase from "../config/supabase.js";
import { fetchAll } from "../utils/db.js";
import { weeklyOffRule, isWorkingDay } from "../utils/weeklyOff.js";

const DEFAULT_BASE_SALARY = 15000;
const SLIP_BUCKET = "salary-slips";
const SLIP_LINK_SECONDS = 10 * 60;

const pad = (n) => String(n).padStart(2, "0");

const todayIST = () =>
  new Date(Date.now() + 5.5 * 60 * 60 * 1000).toISOString().split("T")[0];

// Salary for one employee for one month:
//   one day's pay = base salary ÷ working days in that month
//   net           = one day's pay × paid days
// A working day with no check-in is absent. Days before the joining date are
// unpaid but not counted as absences. Today and future days are assumed
// present, so a month generated early is provisional until refreshed.
export const calculateSalary = ({
  baseSalary,
  location,
  joiningDate,
  attendedDates,
  month,
  year,
  today = todayIST(),
}) => {
  const rule = weeklyOffRule(location);
  const daysInMonth = new Date(year, month, 0).getDate();
  const joined = joiningDate ? String(joiningDate).slice(0, 10) : null;

  let workingDays = 0;
  let paidDays = 0;
  let absentDays = 0;

  for (let day = 1; day <= daysInMonth; day++) {
    if (!isWorkingDay(rule, year, month, day)) continue;
    workingDays++;

    const date = `${year}-${pad(month)}-${pad(day)}`;
    if (joined && date < joined) continue;

    if (date >= today || attendedDates.has(date)) {
      paidDays++;
    } else {
      absentDays++;
    }
  }

  const net =
    workingDays === 0 ? baseSalary : Math.round((baseSalary * paidDays) / workingDays);

  return {
    workingDays,
    paidDays,
    absentDays,
    deduction: baseSalary - net,
    net,
  };
};

// A month's salary is final only once the month is over: until then the
// remaining days are assumed present.
const monthHasEnded = (m, y) => {
  const lastDay = new Date(y, m, 0).getDate();
  return todayIST() > `${y}-${pad(m)}-${pad(lastDay)}`;
};

const MONTH_NAMES = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

const parsePeriod = (month, year) => {
  const m = parseInt(month, 10);
  const y = parseInt(year, 10);
  if (!(m >= 1 && m <= 12) || !(y >= 2000 && y <= 2100)) {
    throw new Error("Valid month and year required");
  }
  return { m, y };
};

// [from, to) of a calendar month in IST, as timestamps
const monthRangeIST = (m, y) => {
  const next = m === 12 ? { m: 1, y: y + 1 } : { m: m + 1, y };
  return {
    from: `${y}-${pad(m)}-01T00:00:00+05:30`,
    to: `${next.y}-${pad(next.m)}-01T00:00:00+05:30`,
  };
};

export const generateMonthlySalary = async (month, year) => {
  const { m, y } = parsePeriod(month, year);
  const { from, to } = monthRangeIST(m, y);
  const lastDay = new Date(y, m, 0).getDate();

  const employees = await fetchAll(() =>
    supabase
      .from("users")
      .select("id, name, base_salary, location, joining_date")
      .eq("role", "employee")
      .order("id"),
  );

  // Every day each employee checked in this month
  const attendance = await fetchAll(() =>
    supabase
      .from("attendance")
      .select("id, user_id, date")
      .gte("date", `${y}-${pad(m)}-01`)
      .lte("date", `${y}-${pad(m)}-${pad(lastDay)}`)
      .order("id"),
  );
  const attendedByUser = new Map();
  for (const row of attendance) {
    if (!attendedByUser.has(row.user_id)) attendedByUser.set(row.user_id, new Set());
    attendedByUser.get(row.user_id).add(String(row.date).slice(0, 10));
  }

  // Approved and already-paid claims raised in this month. Shown on the
  // record for reference only: claims are paid through the claims screen.
  const claims = await fetchAll(() =>
    supabase
      .from("reimbursements")
      .select("id, user_id, amount")
      .in("status", ["approved", "paid"])
      .gte("created_at", from)
      .lt("created_at", to)
      .order("id"),
  );
  const reimbByUser = new Map();
  for (const c of claims) {
    reimbByUser.set(c.user_id, (reimbByUser.get(c.user_id) || 0) + Number(c.amount));
  }

  const existing = await fetchAll(() =>
    supabase
      .from("salary_records")
      .select("*")
      .eq("month", m)
      .eq("year", y)
      .order("id"),
  );
  const existingByUser = new Map(existing.map((r) => [r.user_id, r]));

  const results = [];

  for (const emp of employees) {
    const current = existingByUser.get(emp.id);

    // Never touch a salary that has already been paid
    if (current?.status === "paid") {
      results.push({ ...current, name: emp.name });
      continue;
    }

    const base =
      emp.base_salary == null ? DEFAULT_BASE_SALARY : Number(emp.base_salary) || 0;
    const calc = calculateSalary({
      baseSalary: base,
      location: emp.location,
      joiningDate: emp.joining_date,
      attendedDates: attendedByUser.get(emp.id) || new Set(),
      month: m,
      year: y,
    });

    const { data, error } = await supabase
      .from("salary_records")
      .upsert(
        {
          user_id: emp.id,
          month: m,
          year: y,
          base_salary: base,
          reimbursements: reimbByUser.get(emp.id) || 0,
          working_days: calc.workingDays,
          paid_days: calc.paidDays,
          absent_days: calc.absentDays,
          deduction: calc.deduction,
          net_salary: calc.net,
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
  const { m, y } = parsePeriod(month, year);

  const { data, error } = await supabase
    .from("salary_records")
    .select("*")
    .eq("user_id", userId)
    .eq("month", m)
    .eq("year", y)
    .maybeSingle();

  if (error) throw new Error(error.message);
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
  const { m, y } = parsePeriod(month, year);

  return fetchAll(() =>
    supabase
      .from("salary_records")
      .select(`*, users (id, name, email, designation, location, upi_id, joining_date)`)
      .eq("month", m)
      .eq("year", y)
      .order("created_at", { ascending: true })
      .order("id"),
  );
};

export const markSalaryPaid = async (salaryId) => {
  const { data: record, error: findError } = await supabase
    .from("salary_records")
    .select("id, user_id, month, year, base_salary, status")
    .eq("id", salaryId)
    .maybeSingle();
  if (findError) throw new Error(findError.message);
  if (!record) throw new Error("Salary not found or already paid");
  if (record.status === "paid") throw new Error("Salary not found or already paid");

  const m = Number(record.month);
  const y = Number(record.year);
  if (!monthHasEnded(m, y)) {
    const next = m === 12 ? { m: 1, y: y + 1 } : { m: m + 1, y };
    throw new Error(
      `${MONTH_NAMES[m - 1]} ${y} salary can be paid from 1 ${MONTH_NAMES[next.m - 1]} ${next.y}, once the month's attendance is complete`,
    );
  }

  // Recalculate from the full month's attendance before locking the record,
  // so a salary generated mid-month is not paid on assumed-present days.
  const { data: emp, error: empError } = await supabase
    .from("users")
    .select("id, location, joining_date")
    .eq("id", record.user_id)
    .maybeSingle();
  if (empError) throw new Error(empError.message);

  const lastDay = new Date(y, m, 0).getDate();
  const attendance = await fetchAll(() =>
    supabase
      .from("attendance")
      .select("id, date")
      .eq("user_id", record.user_id)
      .gte("date", `${y}-${pad(m)}-01`)
      .lte("date", `${y}-${pad(m)}-${pad(lastDay)}`)
      .order("id"),
  );

  const base = Number(record.base_salary) || 0;
  const calc = calculateSalary({
    baseSalary: base,
    location: emp?.location,
    joiningDate: emp?.joining_date,
    attendedDates: new Set(attendance.map((a) => String(a.date).slice(0, 10))),
    month: m,
    year: y,
  });

  const { data, error } = await supabase
    .from("salary_records")
    .update({
      working_days: calc.workingDays,
      paid_days: calc.paidDays,
      absent_days: calc.absentDays,
      deduction: calc.deduction,
      net_salary: calc.net,
      status: "paid",
      paid_at: new Date().toISOString(),
    })
    .eq("id", salaryId)
    .eq("status", "pending")
    .select()
    .maybeSingle();

  if (error) throw new Error(error.message);
  if (!data) throw new Error("Salary not found or already paid");
  return data;
};

export const getPayrollSummary = async (month, year) => {
  const { m, y } = parsePeriod(month, year);

  const data = await fetchAll(() =>
    supabase
      .from("salary_records")
      .select("id, base_salary, reimbursements, deduction, absent_days, status")
      .eq("month", m)
      .eq("year", y)
      .order("id"),
  );

  const summary = data.reduce(
    (acc, s) => {
      const base = Number(s.base_salary);
      const deduction = Number(s.deduction) || 0;
      return {
        gross: acc.gross + base,
        reimbursements: acc.reimbursements + Number(s.reimbursements),
        deductions: acc.deductions + deduction,
        absentDays: acc.absentDays + (Number(s.absent_days) || 0),
        // Net payable through payroll: base minus absence deduction.
        // Reimbursements are settled separately through claims.
        net: acc.net + base - deduction,
        paid: acc.paid + (s.status === "paid" ? 1 : 0),
        pending: acc.pending + (s.status === "pending" ? 1 : 0),
      };
    },
    {
      gross: 0,
      reimbursements: 0,
      deductions: 0,
      absentDays: 0,
      net: 0,
      paid: 0,
      pending: 0,
    },
  );

  return summary;
};

// ── Salary slips ─────────────────────────────────────────────────────────────
// Slips live in a private bucket and are only handed out as short-lived
// signed links, to staff or to the employee the slip belongs to.

const ensureSlipBucket = async () => {
  const { error } = await supabase.storage.createBucket(SLIP_BUCKET, {
    public: false,
  });
  if (error && !/already exists/i.test(error.message)) {
    throw new Error(error.message);
  }
};

const SLIP_EXTENSIONS = {
  "application/pdf": "pdf",
  "image/jpeg": "jpg",
  "image/png": "png",
};

export const uploadSalarySlip = async (salaryId, fileBuffer, mimeType) => {
  const ext = SLIP_EXTENSIONS[mimeType];
  if (!ext) throw new Error("Salary slip must be a PDF, JPG or PNG");

  const { data: record, error: findError } = await supabase
    .from("salary_records")
    .select("id, user_id, month, year, slip_path")
    .eq("id", salaryId)
    .maybeSingle();
  if (findError) throw new Error(findError.message);
  if (!record) throw new Error("Salary record not found");

  await ensureSlipBucket();

  const path = `${record.user_id}/${record.year}-${pad(record.month)}-${Date.now()}.${ext}`;
  const { error: uploadError } = await supabase.storage
    .from(SLIP_BUCKET)
    .upload(path, fileBuffer, { contentType: mimeType, upsert: false });
  if (uploadError) throw new Error(uploadError.message);

  const { data, error } = await supabase
    .from("salary_records")
    .update({ slip_path: path, slip_uploaded_at: new Date().toISOString() })
    .eq("id", salaryId)
    .select()
    .single();

  if (error) {
    await supabase.storage.from(SLIP_BUCKET).remove([path]);
    throw new Error(error.message);
  }

  // Replace, don't accumulate: drop the previous file once the new one is saved
  if (record.slip_path) {
    await supabase.storage.from(SLIP_BUCKET).remove([record.slip_path]);
  }

  return data;
};

export const getSalarySlipUrl = async (salaryId, requester) => {
  const { data: record, error } = await supabase
    .from("salary_records")
    .select("id, user_id, slip_path")
    .eq("id", salaryId)
    .maybeSingle();
  if (error) throw new Error(error.message);

  const isStaff = requester.role === "admin" || requester.role === "subadmin";
  if (!record || (!isStaff && record.user_id !== requester.id)) {
    throw new Error("Salary record not found");
  }
  if (!record.slip_path) throw new Error("No salary slip uploaded yet");

  const { data, error: signError } = await supabase.storage
    .from(SLIP_BUCKET)
    .createSignedUrl(record.slip_path, SLIP_LINK_SECONDS);
  if (signError) throw new Error(signError.message);

  return data.signedUrl;
};
