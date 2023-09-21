#!/bin/bash
# This script assumes you're running in /home/$USER/terraform, else modify  line 8
# Generates a text version of the current plan to apply in the ./plans/$DATETIME/ folder
# Saves output of the plan in ./plans/$DATETIME/ 
# Applies the plan without prompting from ./plans/$DATETIME/

DATETIME=$(date +'%d-%m-%y-%H-%M')
DIRECTORY=$(echo ~)/terraform

PLATFORM=$1
if [[ ! -n $PLATFORM ]]; then
  echo "Choose a platform: lxc, docker, or k8s"
  exit 1
fi

pushd "${DIRECTORY}/${PLATFORM}" >/dev/null 2>&1

if [[ ! -d plans ]]; then
  mkdir -p plans && chown -R ${USER}:${USER} plans
fi
if [[ ! -d log ]]; then
  mkdir -p log && chown -R ${USER}:${USER} log
fi
if [[ ! -d plans/$DATETIME ]]; then
  mkdir -p plans/$DATETIME
fi

terraform plan -out=${DIRECTORY}/${PLATFORM}/plans/$DATETIME/plan.tfplan | sed 's/\x1b\[[0-9;]*m//g' > "${DIRECTORY}/${PLATFORM}/plans/${DATETIME}/plan-$DATETIME.txt" &&\
terraform graph -type=plan | dot -Tpng > "${DIRECTORY}/${PLATFORM}/plans/$DATETIME/plan_graph.png" &&\
terraform apply --auto-approve "${DIRECTORY}/${PLATFORM}/plans/$DATETIME/plan.tfplan" &&\

echo "Deployment complete, please verify state is as-desired" &&\

read -p "y or n" answer

if [[ $answer == "n" ]]; then
  terraform destroy --auto-approve #${DIRECTORY}/${PLATFORM}/plans/$DATETIME/plan.tfplan
else
  echo "Congrats!"
fi

popd >/dev/null 2>&1