import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const pkgPath = join(process.cwd(), 'package.json');
const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));

pkg.buildNumber = (pkg.buildNumber || 0) + 1;
writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');

console.log(`Build number incremented to ${pkg.buildNumber}`);
