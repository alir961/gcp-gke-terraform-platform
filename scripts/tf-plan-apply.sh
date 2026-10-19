#!/usr/bin/env bash
# Plan one Terraform module, publish the plan, then apply exactly that plan.
# Usage: scripts/tf-plan-apply.sh <module> <env>   (env: dev | prd)
set -euo pipefail

module="$1"
env="$2"
dir="terraform/${module}"
plan_file="tfplan-${env}"

terraform -chdir="${dir}" init -input=false -backend-config="backends/backend-${env}.hcl"

rc=0
terraform -chdir="${dir}" plan -input=false -no-color -detailed-exitcode \
  -var-file="../environments/${env}/${module}.tfvars" -out="${plan_file}" || rc=$?

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
case "${rc}" in
  0)
    echo "### ${env} / ${module}: no changes" >> "${summary}"
    ;;
  2)
    {
      echo "### ${env} / ${module}: changes applied"
      echo '<details><summary>Plan</summary>'
      echo
      echo '```'
      terraform -chdir="${dir}" show -no-color "${plan_file}"
      echo '```'
      echo '</details>'
    } >> "${summary}"
    terraform -chdir="${dir}" apply -input=false "${plan_file}"
    ;;
  *)
    echo "terraform plan failed for ${module} (${env})" >&2
    exit "${rc}"
    ;;
esac
