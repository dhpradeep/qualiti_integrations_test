#!/bin/bash
 
set -ex
 
PROJECT_ID='332'
API_KEY='xlTTBvkv6V2noPxP3qoej23Id6k9Ldpba3oPezD6'
CLIENT_ID='35672256ebdda10d59ab8f0227c89712'
SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
API_URL='https://7iggpnqgq9.execute-api.us-east-2.amazonaws.com/udbodh/api'
INTEGRATION_JWT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9qZWN0X2lkIjozMzIsImFwaV9rZXlfaWQiOjI0NDUsIm5hbWUiOiIiLCJkZXNjcmlwdGlvbiI6IiIsImljb24iOiIiLCJpbnRlZ3JhdGlvbl9uYW1lIjoiR2l0bGFiIiwib3B0aW9ucyI6e30sImlhdCI6MTYxNjEyNzA3OX0.BjiH6mbzpIm72JUkbtQ6VXVoURZB1Q3QhEuH2A3pb88'
INTEGRATIONS_API_URL='http://39a6ssdf0139cb.ngrok.io'
 
apt-get update -y
apt-get install -y jq
 
#Trigger test run
TEST_RUN_ID="$( \
  curl -X POST -G ${INTEGRATIONS_API_URL}/api/integrations/gitlab/${PROJECT_ID}/events \
    -d 'token='$INTEGRATION_JWT_TOKEN''\
    -d 'triggerType=Deploy'\
  | jq -r '.test_run_id')"
  
echo "$TEST_RUN_ID";
 
AUTHORIZATION_TOKEN="$( \
  curl -X POST -G ${API_URL}/auth/token \
  -H 'x-api-key: '${API_KEY}'' \
  -H 'client_id: '${CLIENT_ID}'' \
  -H 'scopes: '${SCOPES}'' \
  | jq -r '.token')"
 
# Wait until the test run has finished
TOTAL_ITERATION=200
I=1
while : ; do
   RESULT="$( \
   curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
   -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
   -H 'x-api-key: '${API_KEY}'' \
  | jq -r '.[0].finished')"
  if [ "$RESULT" != null ]; then
    break;
  fi
   if [ "$I" -ge "$TOTAL_ITERATION" ]; then
    echo "Exit app for taking too long time.";
    exit 1;
  fi
    I=$((I + 1))
    sleep 15;
done
 
# # Once finished, verify the test result is created and that its passed
TEST_RUN_RESULT="$( \
  curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
    -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
    -H 'x-api-key: '${API_KEY}'' \
  | jq -r '.[0].status' \
)"
echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
if [ "$TEST_RUN_RESULT" = "Passed" ]; then
  exit 0;
fi
exit 1;
