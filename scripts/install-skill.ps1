$ErrorActionPreference = 'Stop'

$SkillName = 'claude-codex-supervisor'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot (Join-Path 'skills' $SkillName)
$TargetRoot = Join-Path $HOME '.claude\skills'
$Target = Join-Path $TargetRoot $SkillName

if (-not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md') -PathType Leaf)) {
    throw "SKILL.md introuvable dans le dépôt cloné : $Source"
}

if (Test-Path -LiteralPath $Target) {
    throw "Le Skill existe déjà : $Target. Aucune modification effectuée. Sauvegardez ou renommez-le manuellement avant une mise à jour."
}

New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
Copy-Item -LiteralPath $Source -Destination $TargetRoot -Recurse -ErrorAction Stop

$InstalledSkill = Join-Path $Target 'SKILL.md'
if (-not (Test-Path -LiteralPath $InstalledSkill -PathType Leaf)) {
    throw "Installation incomplète : $InstalledSkill est introuvable. Le dossier créé n'a pas été supprimé automatiquement."
}

Write-Output "INSTALLATION CONFORME : $InstalledSkill"
Write-Output 'Redémarrez Claude Code ou ouvrez une nouvelle session pour découvrir le Skill.'
