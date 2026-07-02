source ./scripts/env.sh

mvn clean package -DskipTests
docker build -t petclinic:ci .
trivy image petclinic:ci --severity CRITICAL
