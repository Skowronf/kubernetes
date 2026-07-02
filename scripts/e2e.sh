source ./scripts/env.sh

cd ui-tests || exit
npm ci
npx playwright install --with-deps
npx playwright test --shard=1/3
npx playwright test --shard=2/3
npx playwright test --shard=3/3
