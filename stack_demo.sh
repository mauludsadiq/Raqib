#!/bin/bash
# stack_demo.sh — Full stack integration proof: Bay2 + ANKA + Dalil + Raqib

ANKA=~/Downloads/Anka
BAY2=~/Downloads/Bay2
RAQIB=~/Downloads/Raqib
OXFORD="http://localhost:18080"
BAY2_URL="http://localhost:19000"
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

ok()  { echo -e "  ${GREEN}✓${RESET} $1"; }
err() { echo -e "  ${RED}✗${RESET} $1"; exit 1; }
hdr() { echo -e "\n${BOLD}${BLUE}── $1 ${RESET}"; }

lsof -ti:18080,19000 | xargs kill -9 2>/dev/null || true
sleep 1

hdr "Starting Bay2"
mkdir -p $BAY2/out/bay2
rm -f $BAY2/out/bay2/bay2.db
cd $BAY2 && fardrun run --program bay2/src/server.fard --out out/bay2 > /tmp/bay2.log 2>&1 &
BAY2_PID=$!
cd $RAQIB
sleep 2
curl -s $BAY2_URL/health | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d['ok'] else 1)"   && ok "Bay2 running on :19000" || err "Bay2 failed"

hdr "Starting ANKA"
mkdir -p $ANKA/out/node
rm -f $ANKA/out/node/anka_node.db
cd $ANKA && fardrun run --program anka/src/node_process.fard --out out/node > /tmp/anka.log 2>&1 &
ANKA_PID=$!
cd $RAQIB
sleep 2
curl -s $OXFORD/health | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d['ok'] else 1)"   && ok "ANKA running on :18080" || err "ANKA failed"

hdr "Dalil: Browse"
NODE_ID=$(curl -s $OXFORD/health | python3 -c "import sys,json; print(json.load(sys.stdin)['node_id'])")
ok "Dalil browsed node: ${NODE_ID:0:32}..."

hdr "Publishing Claim via Dalil"
python3 -c "
import json
payload = {
  'claim_space': 'research.result.claims',
  'subject': 'stack-demo-2026',
  'predicate': 'reported_finding',
  'object': '3.2C per doubling of CO2',
  'evidence_refs': ['ipcc_ar7:draft'],
  'timestamp_unix_secs': 1775720000
}
open('/tmp/sdpub.json', 'w').write(json.dumps(payload))
"
PUB=$(curl -s -X POST $OXFORD/publish -H "Content-Type: application/json" -d @/tmp/sdpub.json)
DIGEST=$(echo "$PUB" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['digest_hex'])")
[ -n "$DIGEST" ] && ok "Dalil composed: ${DIGEST:0:40}..." || err "Compose failed: $PUB"

hdr "Raqib: Witness Claim"
python3 -c "
import json
payload = {
  'digest_hex': '$DIGEST',
  'witness_node_id': 'raqib-agent-001',
  'validation_type': 'structural',
  'timestamp_unix_secs': 1775721000
}
open('/tmp/sdwitness.json', 'w').write(json.dumps(payload))
"
WITNESS=$(curl -s -X POST $OXFORD/witness -H "Content-Type: application/json" -d @/tmp/sdwitness.json)
echo "$WITNESS" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d['ok'] else 1)"   && ok "Raqib witnessed (unseen -> witnessed)" || err "Witness failed: $WITNESS"

hdr "ANKA: Verify"
SYNC=$(curl -s $OXFORD/sync)
CLAIM_COUNT=$(echo "$SYNC" | python3 -c "import sys,json; print(json.load(sys.stdin)['claim_count'])")
WITNESS_COUNT=$(echo "$SYNC" | python3 -c "import sys,json; print(json.load(sys.stdin)['witness_count'])")
[ "$CLAIM_COUNT" -gt 0 ] && ok "ANKA claim_count: $CLAIM_COUNT" || err "claim_count is 0"
[ "$WITNESS_COUNT" -gt 0 ] && ok "ANKA witness_count: $WITNESS_COUNT" || err "witness_count is 0"

hdr "Bay2: Verify"
BAY2_H=$(curl -s $BAY2_URL/health)
OBJ_COUNT=$(echo "$BAY2_H" | python3 -c "import sys,json; print(json.load(sys.stdin)['object_count'])")
OP_COUNT=$(echo "$BAY2_H" | python3 -c "import sys,json; print(json.load(sys.stdin)['op_count'])")
ok "Bay2 running: object_count=$OBJ_COUNT op_count=$OP_COUNT"
# Store claim directly in Bay2 to verify write path
python3 -c "
import json
payload = {
  'kind': 'anka.claim',
  'payload': {'digest_hex': '$DIGEST'},
  'author_id': 'stack-demo',
  'timestamp_unix_secs': 1775720000,
  'tags': ['research.result.claims']
}
open('/tmp/sdbay2.json', 'w').write(json.dumps(payload))
"
BAY2_STORE=$(curl -s -X POST $BAY2_URL/object -H "Content-Type: application/json" -d @/tmp/sdbay2.json)
echo "$BAY2_STORE" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d['ok'] else 1)"   && ok "Bay2 object stored: $(echo $BAY2_STORE | python3 -c "import sys,json; print(json.load(sys.stdin)['digest'][:32])")"   || err "Bay2 write failed"
BAY2_H2=$(curl -s $BAY2_URL/health)
OBJ_COUNT=$(echo "$BAY2_H2" | python3 -c "import sys,json; print(json.load(sys.stdin)['object_count'])")
OP_COUNT=$(echo "$BAY2_H2" | python3 -c "import sys,json; print(json.load(sys.stdin)['op_count'])")
[ "$OBJ_COUNT" -gt 0 ] && ok "Bay2 object_count: $OBJ_COUNT" || err "Bay2 object_count is 0"
[ "$OP_COUNT" -gt 0 ] && ok "Bay2 op_count: $OP_COUNT" || err "Bay2 op_count is 0"

hdr "Dalil: Read Updated Epistemic State"
QUERY=$(curl -s "$OXFORD/query/research.result.claims/stack-demo-2026")
FINDING=$(echo "$QUERY" | python3 -c "import sys,json; print(json.load(sys.stdin)['single_winner']['winner_value'])")
SCORE=$(echo "$QUERY" | python3 -c "import sys,json; print(json.load(sys.stdin)['single_winner']['winner_score'])")
[ "$FINDING" = "3.2C per doubling of CO2" ] && ok "Dalil read: $FINDING" || err "Read failed"
ok "Dalil score: $SCORE witnesses"
ok "Dalil cite_as: anka:$DIGEST"

hdr "Shutdown and Restart"
kill $ANKA_PID 2>/dev/null
sleep 1
ok "ANKA stopped"
cd $ANKA && fardrun run --program anka/src/node_process.fard --out out/node > /tmp/anka2.log 2>&1 &
ANKA_PID2=$!
cd $RAQIB
sleep 2
curl -s $OXFORD/health | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d['ok'] else 1)"   && ok "ANKA restarted" || err "Restart failed"

hdr "Recovery: Same Claim After Restart"
RECOVERED=$(curl -s "$OXFORD/claim/$DIGEST")
echo "$RECOVERED" | python3 -c "
import sys,json
d=json.load(sys.stdin)
assert d['ok'] and d['envelope']['digest_hex'] == '$DIGEST'
" && ok "Digest $DIGEST recoverable after restart" || err "Recovery failed"
RECOVERED_OBJ=$(echo "$RECOVERED" | python3 -c "import sys,json; print(json.load(sys.stdin)['envelope']['claim']['object'])")
ok "Content: $RECOVERED_OBJ"

hdr "Summary"
echo ""
echo -e "  ${BOLD}Bay2${RESET}    object_count=$OBJ_COUNT  op_count=$OP_COUNT  (direct write verified)"
echo -e "  ${BOLD}ANKA${RESET}    claim_count=$CLAIM_COUNT  witness_count=$WITNESS_COUNT"
echo -e "  ${BOLD}Dalil${RESET}   finding=\"$FINDING\"  score=$SCORE"
echo -e "  ${BOLD}Raqib${RESET}   unseen -> witnessed ✓"
echo -e "  ${BOLD}Recovery${RESET}  anka:${DIGEST:0:40}... ✓"
echo ""
echo -e "${GREEN}${BOLD}Stack demo complete. All layers verified.${RESET}"
echo ""

kill $ANKA_PID2 $BAY2_PID 2>/dev/null
