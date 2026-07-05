# Claude Code statusline - 2 lines
# Line 1: model  5h%(reset)  7d%(reset)  ctx:%(size)
# Line 2: branch  +added -removed  tok:in/out
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

$reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
$raw = $reader.ReadToEnd()

$json = $null
try { $json = $raw | ConvertFrom-Json -ErrorAction Stop } catch {}

# --- helpers ---
function Get-Prop {
    param($obj, [string]$path)
    $cur = $obj
    foreach ($p in $path.Split('.')) {
        if ($null -eq $cur) { return $null }
        $cur = $cur.$p
    }
    return $cur
}
function Fmt-Pct {
    param($v)
    if ($null -eq $v -or "$v" -eq "") { return "?" }
    return ("{0}%" -f [math]::Round([double]$v))
}
function Fmt-Remain {
    param($resetsAt)
    if ($null -eq $resetsAt -or "$resetsAt" -eq "") { return "" }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $diff = [int64]$resetsAt - $now
    if ($diff -le 0) { return "now" }
    $d = [math]::Floor($diff / 86400)
    $h = [math]::Floor(($diff % 86400) / 3600)
    $m = [math]::Floor(($diff % 3600) / 60)
    if ($d -gt 0) { return ("{0}d {1}h" -f $d, $h) }
    if ($h -gt 0) { return ("{0}h" -f $h) }
    return ("{0}m" -f $m)
}
$esc = [char]27
$RST = "$esc[0m"
function Col { param($code, $txt) return "$esc[${code}m$txt$RST" }

# --- gather data ---
$model = Get-Prop $json "model.display_name"; if (-not $model) { $model = "?" }

$fhPct   = Get-Prop $json "rate_limits.five_hour.used_percentage"
$fhReset = Get-Prop $json "rate_limits.five_hour.resets_at"
$sdPct   = Get-Prop $json "rate_limits.seven_day.used_percentage"
$sdReset = Get-Prop $json "rate_limits.seven_day.resets_at"

$ctxPct  = Get-Prop $json "context_window.used_percentage"
$ctxSize = Get-Prop $json "context_window.context_window_size"
$ctxSizeStr = if ($ctxSize) { "{0}k" -f [math]::Round([double]$ctxSize / 1000) } else { "?" }

$dir     = Get-Prop $json "workspace.current_dir"
$root    = Get-Prop $json "workspace.project_dir"; if (-not $root) { $root = $dir }
$added   = Get-Prop $json "cost.total_lines_added";   if ($null -eq $added)   { $added = 0 }
$removed = Get-Prop $json "cost.total_lines_removed"; if ($null -eq $removed) { $removed = 0 }
$cost    = Get-Prop $json "cost.total_cost_usd"; if ($null -eq $cost) { $cost = 0 }

# git branch (only if current dir is a git repo)
$branch = ""
if ($dir) {
    try { $branch = (git -C "$dir" rev-parse --abbrev-ref HEAD 2>$null) } catch {}
    if ($branch) { $branch = "$branch".Trim() }
}

# --- separator ---
$SEP = " " + (Col "0;90" "|") + " "

# --- line 1 ---
$fhStr = Fmt-Pct $fhPct; $fhRem = Fmt-Remain $fhReset
if ($fhRem) { $fhStr = "$fhStr($fhRem)" }
$sdStr = Fmt-Pct $sdPct; $sdRem = Fmt-Remain $sdReset
if ($sdRem) { $sdStr = "$sdStr($sdRem)" }
$l1 = @(
    (Col "0;33" $model),
    (Col "0;36" $fhStr),
    (Col "0;35" $sdStr),
    (Col "0;32" ("ctx:{0}({1})" -f (Fmt-Pct $ctxPct), $ctxSizeStr))
) -join $SEP

# --- line 2 ---
$seg2 = @()
if ($branch) { $seg2 += (Col "1;32" $branch) } else { $seg2 += (Col "0;90" "null") }
$seg2 += ((Col "0;32" "+$added") + " " + (Col "0;31" "-$removed"))
$seg2 += (Col "0;36" ("$" + ("{0:0.000}" -f [double]$cost)))
if ($root) { $seg2 += (Col "0;90" $root) }
$l2 = $seg2 -join $SEP

[Console]::Out.Write("$l1`n$l2")
