from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path

PACKAGE_ROOT = Path(__file__).resolve().parent


def replace_exact(path: Path, old: str, new: str, *, expected_max: int | None = None) -> int:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if expected_max is not None and count > expected_max:
        raise RuntimeError(f'{path}: found {count} occurrences, expected <= {expected_max}')
    if count:
        path.write_text(text.replace(old, new), encoding='utf-8')
    return count


def remove_function_block(path: Path, start_marker: str, next_marker: str) -> bool:
    text = path.read_text(encoding='utf-8')
    start = text.find(start_marker)
    if start < 0:
        return False
    end = text.find(next_marker, start)
    if end < 0:
        raise RuntimeError(f'{path}: cannot locate end marker for removable block')
    new_text = text[:start] + text[end:]
    path.write_text(new_text, encoding='utf-8')
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description='Apply NanoBio analyzer/MealPlan bug fixes.')
    parser.add_argument('project_root', nargs='?', default='.', help='NanoBio repository root')
    args = parser.parse_args()

    root = Path(args.project_root).resolve()
    pubspec = root / 'pubspec.yaml'
    if not pubspec.is_file() or 'name: nano_app' not in pubspec.read_text(encoding='utf-8'):
        raise SystemExit(f'Not a NanoBio nano_app repository: {root}')

    targets = {
        'resolver': root / 'lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart',
        'schedule': root / 'lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_timeline.dart',
        'auth_controller': root / 'lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart',
        'auth_providers': root / 'lib/app_versions/v2/features/auth/providers/auth_providers.dart',
        'supabase_test': root / 'test/docs/supabase_config_contract_test.dart',
        'loading_state': root / 'lib/core/theme/primitives/states/loading_state.dart',
        'vietqr': root / 'lib/core/payments/viet_qr_payload_builder.dart',
        'resolver_test': root / 'test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart',
    }
    missing = [str(p) for key, p in targets.items() if key not in {'resolver_test'} and not p.is_file()]
    if missing:
        raise SystemExit('Missing required project files:\n- ' + '\n- '.join(missing))

    stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_root = root / f'.nanobio_fix_backup_{stamp}'
    for path in targets.values():
        if path.exists():
            relative = path.relative_to(root)
            backup = backup_root / relative
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, backup)

    changed: list[str] = []

    # 1) Meal image resolver: exact allow-list + backwards-compatible API.
    resolver_src = PACKAGE_ROOT / 'lib/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver.dart'
    shutil.copy2(resolver_src, targets['resolver'])
    changed.append(str(targets['resolver'].relative_to(root)))

    targets['resolver_test'].parent.mkdir(parents=True, exist_ok=True)
    resolver_test_src = PACKAGE_ROOT / 'test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart'
    shutil.copy2(resolver_test_src, targets['resolver_test'])
    changed.append(str(targets['resolver_test'].relative_to(root)))

    # 2) Analyzer severity-4 cleanup: truly unused imports.
    if replace_exact(
        targets['schedule'],
        "import '../controllers/lifestyle_schedule_controller.dart';\n",
        '',
        expected_max=1,
    ):
        changed.append(str(targets['schedule'].relative_to(root)))

    if replace_exact(
        targets['auth_providers'],
        "import 'auth_dependencies.dart';\n\n",
        '',
        expected_max=1,
    ):
        changed.append(str(targets['auth_providers'].relative_to(root)))

    # 3) Riverpod 3.x: copyWithPrevious is @internal. Preserve the resolved
    # route state by simply not publishing an artificial loading state while
    # imperative refresh/account mutations execute.
    auth_text = targets['auth_controller'].read_text(encoding='utf-8')
    internal_call = "    state = const AsyncLoading<AuthRouteState>().copyWithPrevious(previousState);\n"
    internal_count = auth_text.count(internal_call)
    if internal_count not in (0, 3):
        raise RuntimeError(
            f"{targets['auth_controller']}: expected 0 or 3 copyWithPrevious calls, found {internal_count}"
        )
    if internal_count:
        auth_text = auth_text.replace(internal_call, '')
        previous_decl = "    final previousState = state;\n"
        previous_count = auth_text.count(previous_decl)
        if previous_count == 3:
            # refresh() and signOut() no longer need a local previous state.
            # _runAccountMutation() still needs it to restore state on failure.
            first = auth_text.find(previous_decl)
            auth_text = auth_text[:first] + auth_text[first + len(previous_decl):]
            second = auth_text.find(previous_decl)
            auth_text = auth_text[:second] + auth_text[second + len(previous_decl):]
        elif previous_count != 1:
            raise RuntimeError(
                f"{targets['auth_controller']}: expected 1 or 3 previousState declarations after cleanup, found {previous_count}"
            )
        old_comment = (
            '    // Preserve the last resolved route while the mutation runs. This keeps the\n'
            '    // login page mounted for an unauthenticated account (so validation/errors\n'
            '    // are not lost) and keeps an authenticated surface stable during refreshes.\n'
        )
        new_comment = (
            '    // Preserve the last resolved route while the mutation runs by leaving\n'
            '    // [state] unchanged until a new route is resolved. Riverpod 3 marks\n'
            '    // AsyncValue.copyWithPrevious as internal application-facing API.\n'
        )
        auth_text = auth_text.replace(old_comment, new_comment)
        targets['auth_controller'].write_text(auth_text, encoding='utf-8')
        changed.append(str(targets['auth_controller'].relative_to(root)))

    # 4) Remove dead helper reported by analyzer.
    if remove_function_block(
        targets['supabase_test'],
        'String _functionBlock(String sql, String functionName) {',
        'String _lastFunctionBlock(String sql, String functionName) {',
    ):
        changed.append(str(targets['supabase_test'].relative_to(root)))

    # 5) Flutter API deprecation with a real public replacement.
    if replace_exact(
        targets['loading_state'],
        'TickerMode.of(context)',
        'TickerMode.valuesOf(context).enabled',
        expected_max=1,
    ):
        changed.append(str(targets['loading_state'].relative_to(root)))

    # 6) Style lint in VietQR. Keep behavior byte-for-byte equivalent.
    vietqr = targets['vietqr'].read_text(encoding='utf-8')
    old_consumer = (
        "    final consumerAccount =\n"
        "        _emv('00', normalizedBankBin) +\n"
        "        _emv('01', normalizedAccountNumber);\n"
    )
    new_consumer = (
        "    final consumerAccount =\n"
        "        \"${_emv('00', normalizedBankBin)}${_emv('01', normalizedAccountNumber)}\";\n"
    )
    old_merchant = (
        "    final merchantAccount =\n"
        "        _emv('00', 'A000000727') +\n"
        "        _emv('01', consumerAccount) +\n"
        "        _emv('02', 'QRIBFTTA');\n"
    )
    new_merchant = (
        "    final merchantAccount =\n"
        "        \"${_emv('00', 'A000000727')}${_emv('01', consumerAccount)}${_emv('02', 'QRIBFTTA')}\";\n"
    )
    old_crc = (
        "    final withoutCrc =\n"
        "        _emv('00', '01') +\n"
        "        _emv('01', '12') +\n"
        "        _emv('38', merchantAccount) +\n"
        "        _emv('53', '704') +\n"
        "        _emv('54', amount.toString()) +\n"
        "        _emv('58', 'VN') +\n"
        "        _emv('59', normalizedAccountName) +\n"
        "        _emv('62', additionalData) +\n"
        "        '6304';\n"
    )
    new_crc = (
        "    final withoutCrc =\n"
        "        \"${_emv('00', '01')}${_emv('01', '12')}${_emv('38', merchantAccount)}\"\n"
        "        \"${_emv('53', '704')}${_emv('54', amount.toString())}${_emv('58', 'VN')}\"\n"
        "        \"${_emv('59', normalizedAccountName)}${_emv('62', additionalData)}6304\";\n"
    )
    before = vietqr
    for old, new in [(old_consumer, new_consumer), (old_merchant, new_merchant), (old_crc, new_crc)]:
        if old in vietqr:
            vietqr = vietqr.replace(old, new)
    if vietqr != before:
        targets['vietqr'].write_text(vietqr, encoding='utf-8')
        changed.append(str(targets['vietqr'].relative_to(root)))

    # 7) Project bugfix documentation/worklog required by the NanoBio workflow.
    doc_pairs = [
        (
            PACKAGE_ROOT / 'docs/fixbug/analyzer-cleanup-20260815/README.md',
            root / 'docs/fixbug/analyzer-cleanup-20260815/README.md',
        ),
        (
            PACKAGE_ROOT / 'docs/worklog/2026-08-15/meal-image-analyzer-bugfix.md',
            root / 'docs/worklog/2026-08-15/meal-image-analyzer-bugfix.md',
        ),
    ]
    for source, destination in doc_pairs:
        destination.parent.mkdir(parents=True, exist_ok=True)
        previous = destination.read_text(encoding='utf-8') if destination.exists() else None
        content = source.read_text(encoding='utf-8')
        if previous != content:
            if destination.exists():
                backup = backup_root / destination.relative_to(root)
                backup.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(destination, backup)
            destination.write_text(content, encoding='utf-8')
            changed.append(str(destination.relative_to(root)))

    print('Applied NanoBio fix package successfully.')
    print(f'Backup: {backup_root}')
    if changed:
        print('Changed files:')
        for item in dict.fromkeys(changed):
            print(f'  - {item}')
    else:
        print('No additional changes were necessary; project already matched the fix.')


if __name__ == '__main__':
    main()
