// Run the dev-process-toolkit probes that grade a bug's spec files on a
// checkout, before the files are committed, and print only the rows that
// name the given keys. Usage:
//
//   bun run <skill>/scripts/spec_probes.ts <toolkit root> <checkout> <keys regex>
//
// <toolkit root> is the loaded dev-process-toolkit copy, <checkout> the spec
// worktree with the drafts copied in, <keys regex> e.g. 'APP-48[2-6]|M48[2-6]'.
// Exit 0 when every probe is clean for those keys, 1 otherwise.

const [toolkit, root, keys] = process.argv.slice(2);
if (!toolkit || !root || !keys) {
  console.error("usage: bun run spec_probes.ts <toolkit root> <checkout> <keys regex>");
  process.exit(2);
}

const PROBES: Array<[string, string]> = [
  ["scan_fr_summary_altitude.ts", "runFrSummaryAltitudeProbe"],
  ["scan_plan_narrative_altitude.ts", "runPlanNarrativeAltitudeProbe"],
  ["plan_identity_mode_conditional.ts", "runPlanIdentityModeConditionalProbe"],
  ["needs_technical_review_consistency.ts", "runNeedsTechnicalReviewConsistencyProbe"],
  ["identity_mode_conditional.ts", "runIdentityModeConditionalProbe"],
  ["frontmatter_milestone_not_archived.ts", "runFrontmatterMilestoneNotArchivedProbe"],
  ["plan_task_fr_coverage.ts", "runPlanTaskFrCoverageProbe"],
  ["plan_file_single_milestone.ts", "runPlanFileSingleMilestoneProbe"],
  ["bug_fr_shape.ts", "runBugFrShapeProbe"],
];

const mine = new RegExp(keys);
let dirty = false;
for (const [file, fn] of PROBES) {
  try {
    const mod = await import(`${toolkit}/adapters/_shared/src/${file}`);
    const report = await mod[fn](root);
    const rows = [
      ...(report.violations ?? []),
      ...(report.notes ?? []).map((n: unknown) => (typeof n === "string" ? { note: n } : n)),
    ].filter((row) => mine.test(JSON.stringify(row)));
    console.log(`${fn}: ${rows.length === 0 ? "clean" : `${rows.length} row(s)`}`);
    for (const row of rows as Array<Record<string, unknown>>) {
      dirty = true;
      const text = String(row.note ?? row.message ?? JSON.stringify(row)).split("\n")[0];
      console.log(`  ${row.severity ?? ""} ${text}`);
    }
  } catch (e) {
    dirty = true;
    console.log(`${fn}: ERROR ${(e as Error).message.split("\n")[0]}`);
  }
}
process.exit(dirty ? 1 : 0);
