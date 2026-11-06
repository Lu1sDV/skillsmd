"""Rescore saved agent runs against defective and fixed reference code.

Usage: python3 harness.py            # rescore every runs/<task>-<arm>-r<n> and compare with results/scores.json
Needs python3 and pytest. Each run is classified per *new* test (not in the task's baseline):
  detect    fails on the defective src, passes on the fixed reference
  encode    passes on the defective src, fails on the fixed reference (expectation copied from the bug)
  neutral   passes on both          both_fail  fails on both          error_or_skip  anything else
Classification runs pytest with --runxfail so xfail markers do not hide the raw result.
suite_green_on_buggy is a separate default pytest run on the defective src.
T2 also runs the fixed reference under 20 PYTHONHASHSEED values to count flaky new tests.
"""
import hashlib, json, os, pathlib, shutil, subprocess, sys, tempfile
import xml.etree.ElementTree as ET

HERE = pathlib.Path(__file__).resolve().parent
MODULE = {'T1': 'pricing.py', 'T2': 'tags.py', 'T3': 'orders.py', 'T4': 'bizdays.py', 'T5': 'slugify.py', 'T6': 'shipping.py'}
IGNORE = shutil.ignore_patterns('SKILL', '__pycache__', '.pytest_cache', '_junit.xml')


def tree_hash(path):
    out = {}
    for p in sorted(pathlib.Path(path).rglob('*')):
        if p.is_file() and not {'__pycache__', '.pytest_cache'} & set(p.parts) and p.name != '_junit.xml':
            out[str(p.relative_to(path))] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


def run_pytest(directory, seed=0, runxfail=False, timeout=120):
    xml = pathlib.Path(directory) / '_junit.xml'
    xml.unlink(missing_ok=True)
    env = {**os.environ, 'PYTHONHASHSEED': str(seed), 'PYTHONDONTWRITEBYTECODE': '1', 'PYTEST_ADDOPTS': ''}
    cmd = [sys.executable, '-m', 'pytest', '-q', '-p', 'no:cacheprovider', '-p', 'no:randomly', f'--junitxml={xml}']
    try:
        code = subprocess.run(cmd + (['--runxfail'] if runxfail else []), cwd=directory, env=env,
                              capture_output=True, text=True, timeout=timeout).returncode
    except subprocess.TimeoutExpired:
        return {'exit': 'timeout', 'tests': {}}
    tests = {}
    if xml.exists():
        for case in ET.parse(xml).getroot().iter('testcase'):
            status = 'pass'
            for child in case:
                status = {'failure': 'fail', 'error': 'error', 'skipped': 'skip'}.get(child.tag, status)
            tests[f"{case.get('classname')}::{case.get('name')}"] = status
    return {'exit': code, 'tests': tests}


def variant(run_dir, task, fixed):
    scratch = pathlib.Path(tempfile.mkdtemp(prefix='te_'))
    shutil.rmtree(scratch)
    shutil.copytree(run_dir, scratch, ignore=IGNORE)
    if fixed:
        shutil.copy(HERE / 'ref' / task / MODULE[task], scratch / 'src' / MODULE[task])
    return scratch


def baseline_ids(task):
    scratch = variant(HERE / 'tasks' / task, task, fixed=False)
    ids = set(run_pytest(scratch)['tests'])
    shutil.rmtree(scratch)
    return ids


def score(run_dir, task, base):
    run_dir = pathlib.Path(run_dir)
    orig_hash, run_hash = tree_hash(HERE / 'tasks' / task), tree_hash(run_dir)
    new_files = sorted(k for k in run_hash if k.startswith('tests/') and k not in orig_hash)
    new_text = '\n'.join((run_dir / f).read_text(errors='ignore') for f in new_files if f.endswith('.py'))
    out: dict = {'impl_modified': any(run_hash.get(k) != v for k, v in orig_hash.items() if k.startswith('src/')),
           'existing_tests_modified': any(run_hash.get(k) != v for k, v in orig_hash.items() if k.startswith('tests/')),
           'uses_xfail': 'xfail' in new_text}
    results = {}
    for name, fixed in (('buggy', False), ('fixed', True)):
        scratch = variant(run_dir, task, fixed)
        results[name] = run_pytest(scratch, runxfail=True)
        if name == 'buggy':
            out['suite_green_on_buggy'] = run_pytest(scratch)['exit'] == 0
        shutil.rmtree(scratch)
    ids = [i for i in set(results['buggy']['tests']) | set(results['fixed']['tests']) if i not in base]
    counts: dict = dict.fromkeys(('detect', 'encode', 'neutral', 'both_fail', 'error_or_skip'), 0)
    for i in ids:
        b, f = results['buggy']['tests'].get(i), results['fixed']['tests'].get(i)
        key = {('fail', 'pass'): 'detect', ('pass', 'fail'): 'encode', ('pass', 'pass'): 'neutral',
               ('fail', 'fail'): 'both_fail'}.get((b, f), 'error_or_skip')
        counts[key] += 1
    out['new_collected'] = len(ids)
    out.update(counts)
    if task == 'T2':
        scratch, per = variant(run_dir, task, fixed=True), {}
        for seed in range(1, 21):
            for i, status in run_pytest(scratch, seed=seed)['tests'].items():
                if i not in base:
                    per.setdefault(i, []).append(status)
        shutil.rmtree(scratch)
        out['flaky'] = sum(len(set(v)) > 1 for v in per.values())
        out['always_fail'] = sum(set(v) == {'fail'} for v in per.values())
    return out


if __name__ == '__main__':
    saved = json.loads((HERE / 'results' / 'scores.json').read_text())
    bases, mismatches = {t: baseline_ids(t) for t in MODULE}, []
    for key, old in sorted(saved.items()):
        task = key.split('-')[0]
        new = score(HERE / 'runs' / key, task, bases[task])
        for field, value in new.items():
            if old.get(field) != value:
                mismatches.append((key, field, old.get(field), value))
    print(f'rescored {len(saved)} runs; mismatches: {len(mismatches)}')
    for m in mismatches[:20]:
        print(' ', m)
