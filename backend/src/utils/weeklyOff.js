// Weekly offs, shared by salary calculation and the attendance views.
//
// Srinagar (incl. Hyderpora) / Jammu staff: Monday off.
// Noida / Delhi staff:    every Sunday plus the 2nd and 3rd Saturday off.
// Anyone else:            Sunday off.
// The office is read from the employee's "location" field.
export const weeklyOffRule = (location) => {
  const loc = String(location || "").toLowerCase();
  if (/srinagar|hyderpora|jammu/.test(loc)) return "monday";
  if (/noida|delhi/.test(loc)) return "sunday_and_2nd_3rd_saturday";
  return "sunday";
};

export const isWorkingDay = (rule, year, month, day) => {
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay(); // 0 = Sunday
  if (rule === "monday") return weekday !== 1;
  if (weekday === 0) return false;
  if (rule === "sunday_and_2nd_3rd_saturday" && weekday === 6) {
    const nth = Math.ceil(day / 7); // 1st, 2nd, ... Saturday of the month
    return nth !== 2 && nth !== 3;
  }
  return true;
};

// Whether `date` ("YYYY-MM-DD") is a working day for someone at `location`.
// Returns null when the date is not valid.
export const isWorkingDate = (location, date) => {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(date || ""));
  if (!match) return null;
  const [year, month, day] = match.slice(1).map(Number);
  return isWorkingDay(weeklyOffRule(location), year, month, day);
};
