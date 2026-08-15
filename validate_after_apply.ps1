param(
    [Parameter(Position = 0)]
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectRoot).Path
Push-Location $root
try {
    Write-Host "== NanoBio targeted validation =="
    Write-Host "Project: $root"
    & flutter --version
    & dart --version

    $formatPaths = @(
        "lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart",
        "lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_timeline.dart",
        "lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart",
        "lib/app_versions/v2/features/auth/providers/auth_providers.dart",
        "lib/core/theme/primitives/states/loading_state.dart",
        "lib/core/payments/viet_qr_payload_builder.dart",
        "test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart",
        "test/docs/supabase_config_contract_test.dart"
    )

    & dart format @formatPaths
    if ($LASTEXITCODE -ne 0) { throw "dart format failed" }

    & flutter analyze @formatPaths
    if ($LASTEXITCODE -ne 0) { throw "targeted flutter analyze failed" }

    $tests = @(
        "test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart",
        "test/app_versions/v2/features/auth/auth_controller_sync_failure_test.dart",
        "test/docs/supabase_config_contract_test.dart",
        "test/core/payments/viet_qr_payload_builder_test.dart"
    )
    & flutter test @tests
    if ($LASTEXITCODE -ne 0) { throw "targeted flutter test failed" }

    Write-Host "Targeted validation passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
