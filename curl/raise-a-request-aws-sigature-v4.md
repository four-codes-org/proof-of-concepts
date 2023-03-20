[raise-a-request-aws-sigature-v4](https://code.dblock.org/2022/07/11/making-sigv4-authenticated-requests-to-managed-opensearch.html).md


```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

curl \
  --verbose \
  --request GET "https://...us-west-2.es.amazonaws.com" \
  --aws-sigv4 "aws:amz:us-west-2:es" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  -H "x-amz-security-token:$AWS_SESSION_TOKEN"
```