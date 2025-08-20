#!/usr/bin/env bash
set -euo pipefail

REPORT="${1:-checkov-report.json}"

jq -r '
  def reports: if type=="array" then . else [.] end;
  def tf: reports | map(select(.check_type=="terraform"));
  def failed: tf | map(.results.failed_checks // []) | add;

  {
    totals_by_severity:
      (failed | group_by(.severity)
              | map({severity: .[0].severity, count: length})),
    top_checks:
      (failed | group_by(.check_id)
              | map({check_id: .[0].check_id, name: .[0].check_name, severity: .[0].severity, count: length})
              | sort_by(-.count) | .[0:25]),
    noisiest_files:
      (failed | group_by(.file_path)
              | map({file: .[0].file_path, count: length})
              | sort_by(-.count) | .[0:20])
  }
' "$REPORT"
