// Supabase caps a single response at 1000 rows by default, so list queries
// must page. `build` returns a fresh, fully-ordered query on every call.
export const fetchAll = async (build, pageSize = 1000) => {
  const rows = [];
  for (let from = 0; ; from += pageSize) {
    const { data, error } = await build().range(from, from + pageSize - 1);
    if (error) throw new Error(error.message);
    rows.push(...data);
    if (data.length < pageSize) break;
  }
  return rows;
};
