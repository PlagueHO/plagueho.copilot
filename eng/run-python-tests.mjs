import { spawnSync } from 'node:child_process';
import process from 'node:process';

const testArguments = [
  '-m',
  'unittest',
  'discover',
  '-s',
  'tests/discover-multitenant-service-updates',
  '-p',
  'test_*.py',
];

function probe(command, prefixArguments = []) {
  const result = spawnSync(command, [...prefixArguments, '--version'], {
    encoding: 'utf8',
  });
  const version = `${result.stdout ?? ''}${result.stderr ?? ''}`;
  return result.status === 0 && /Python 3\./.test(version);
}

function findPython() {
  const candidates =
    process.platform === 'win32'
      ? [
          ['py', ['-3']],
          ['python3', []],
          ['python', []],
        ]
      : [
          ['python3', []],
          ['python', []],
        ];

  for (const [command, prefixArguments] of candidates) {
    if (probe(command, prefixArguments)) {
      return { command, prefixArguments };
    }
  }

  if (process.platform === 'win32') {
    const result = spawnSync('uv', ['python', 'find', '3.13'], {
      encoding: 'utf8',
    });
    const command = result.stdout?.trim();
    if (result.status === 0 && command && probe(command)) {
      return { command, prefixArguments: [] };
    }
  }

  throw new Error(
    'Python 3 was not found. Install Python 3 or make it available on PATH.',
  );
}

let python;
try {
  python = findPython();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}

const result = spawnSync(
  python.command,
  [...python.prefixArguments, ...testArguments],
  { stdio: 'inherit' },
);

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
