source ./scripts/env.sh

mvn clean package -DskipTests
docker build -t ghcr.io/skowronf/enterprise-platform:ci .
docker push ghcr.io/skowronf/enterprise-platform:ci
#trivy image petclinic:ci --severity CRITICAL
#docker build -t petclinic:ci .
