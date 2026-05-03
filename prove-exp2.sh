#!/bin/bash
echo "================================================"
echo "  EXPERIMENT 2 PROOF — Aakash E | RA2311026010022"
echo "  Blue-Green Deployment"
echo "================================================"

WORKER_IP="54.165.36.61"
KUBECONFIG="/var/lib/jenkins/.kube/config"

echo ""
echo "--- 0. AUTO-FIXING KUBECONFIG ---"
sudo sed -i "s|https://.*:6443|https://172.31.45.159:6443|" $KUBECONFIG
sudo sed -i '/certificate-authority-data/d' $KUBECONFIG
grep -q 'insecure-skip-tls-verify' $KUBECONFIG || \
  sudo sed -i '/server:/a\    insecure-skip-tls-verify: true' $KUBECONFIG
echo "Kubeconfig fixed!"

echo ""
echo "--- 1. CLUSTER STATUS ---"
kubectl get nodes --kubeconfig=$KUBECONFIG

echo ""
echo "--- 2. BOTH DEPLOYMENTS RUNNING ---"
kubectl get deployments -l app=demo-app --kubeconfig=$KUBECONFIG

echo ""
echo "--- 3. ALL PODS (BLUE + GREEN) ---"
kubectl get pods -l app=demo-app -o wide --kubeconfig=$KUBECONFIG

echo ""
echo "--- 4. CURRENT SERVICE SELECTOR (who gets traffic) ---"
kubectl get svc demo-app-service -o jsonpath='{.spec.selector}' \
  --kubeconfig=$KUBECONFIG
echo ""

echo ""
echo "--- 5. LIVE APP HEALTH CHECK ---"
curl -s http://${WORKER_IP}:30090/health | python3 -m json.tool

echo ""
echo "--- 6. SWITCHING TRAFFIC TO BLUE ---"
kubectl patch service demo-app-service \
  -p '{"spec":{"selector":{"app":"demo-app","slot":"blue"}}}' \
  --kubeconfig=$KUBECONFIG
echo "Traffic → BLUE"
sleep 2
curl -s http://${WORKER_IP}:30090/health | python3 -m json.tool

echo ""
echo "--- 7. SWITCHING TRAFFIC TO GREEN ---"
kubectl patch service demo-app-service \
  -p '{"spec":{"selector":{"app":"demo-app","slot":"green"}}}' \
  --kubeconfig=$KUBECONFIG
echo "Traffic → GREEN"
sleep 2
curl -s http://${WORKER_IP}:30090/health | python3 -m json.tool

echo ""
echo "--- 8. DOCKER IMAGES ---"
docker images | grep -E "blue-app|green-app"

echo ""
echo "--- 9. EXP 1 STILL WORKING ---"
curl -s http://${WORKER_IP}:30080/health | python3 -m json.tool

echo ""
echo "================================================"
echo "  ALL CHECKS COMPLETE"
echo "================================================"
